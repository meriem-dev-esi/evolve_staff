alter table public.enrollments
add column if not exists paid_at timestamptz;

create index if not exists enrollments_paid_at_idx
on public.enrollments (paid_at)
where payment_status = 'paid';

create table if not exists public.admin_financial_entries (
  id uuid primary key default gen_random_uuid(),
  entry_type text not null check (entry_type in ('expense', 'refund')),
  amount_minor_units bigint not null check (amount_minor_units > 0),
  category text not null check (length(trim(category)) between 1 and 80),
  note text not null check (length(trim(note)) between 1 and 500),
  occurred_at timestamptz not null,
  enrollment_id uuid references public.enrollments(id) on delete restrict,
  recorded_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  constraint admin_financial_entry_enrollment_type check (
    (entry_type = 'expense' and enrollment_id is null)
    or (entry_type = 'refund' and enrollment_id is not null)
  )
);

create index if not exists admin_financial_entries_month_idx
on public.admin_financial_entries (occurred_at, entry_type);

create index if not exists admin_financial_entries_enrollment_idx
on public.admin_financial_entries (enrollment_id)
where entry_type = 'refund';

alter table public.admin_financial_entries enable row level security;
grant select on public.admin_financial_entries to service_role;

create or replace function public.create_admin_financial_entry(
  p_entry_type text,
  p_amount_minor_units bigint,
  p_category text,
  p_note text,
  p_occurred_at timestamptz,
  p_enrollment_id uuid,
  p_recorded_by uuid
)
returns public.admin_financial_entries
language plpgsql
security definer
set search_path = public
as $$
declare
  paid_amount_minor_units bigint;
  previous_refunds_minor_units bigint;
  inserted_entry public.admin_financial_entries;
begin
  if not exists (
    select 1 from public.profiles
    where id = p_recorded_by and role = 'admin'
  ) then
    raise exception 'Administrator access required';
  end if;

  if p_entry_type not in ('expense', 'refund')
     or p_amount_minor_units <= 0
     or length(trim(p_category)) not between 1 and 80
     or length(trim(p_note)) not between 1 and 500
     or p_occurred_at is null then
    raise exception 'Invalid financial entry';
  end if;

  if p_entry_type = 'expense' then
    if p_enrollment_id is not null then
      raise exception 'Expenses cannot reference enrollments';
    end if;
  else
    if p_enrollment_id is null then
      raise exception 'A paid enrollment is required for a refund';
    end if;

    select round(payment_amount * 100)::bigint
    into paid_amount_minor_units
    from public.enrollments
    where id = p_enrollment_id
      and payment_status = 'paid'
    for update;

    if not found or paid_amount_minor_units is null or paid_amount_minor_units <= 0 then
      raise exception 'Refunds require a paid enrollment with a recorded amount';
    end if;

    select coalesce(sum(amount_minor_units), 0)::bigint
    into previous_refunds_minor_units
    from public.admin_financial_entries
    where enrollment_id = p_enrollment_id
      and entry_type = 'refund';

    if previous_refunds_minor_units + p_amount_minor_units > paid_amount_minor_units then
      raise exception 'Refund total cannot exceed the recorded payment';
    end if;
  end if;

  insert into public.admin_financial_entries (
    entry_type,
    amount_minor_units,
    category,
    note,
    occurred_at,
    enrollment_id,
    recorded_by
  )
  values (
    p_entry_type,
    p_amount_minor_units,
    trim(p_category),
    trim(p_note),
    p_occurred_at,
    p_enrollment_id,
    p_recorded_by
  )
  returning * into inserted_entry;

  return inserted_entry;
end;
$$;

revoke all on function public.create_admin_financial_entry(
  text, bigint, text, text, timestamptz, uuid, uuid
) from public, anon, authenticated;
grant execute on function public.create_admin_financial_entry(
  text, bigint, text, text, timestamptz, uuid, uuid
) to service_role;
