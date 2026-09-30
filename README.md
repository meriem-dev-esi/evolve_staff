# evolve_staff

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Shared student messaging

The staff portal uses the same Supabase project and direct-message tables as
the Evolve School website. Student conversations are stored in
`public.conversations`, and messages are stored in `public.direct_messages`.
Apply the website migration
`supabase/migrations/20261001_student_teacher_messaging.sql` to the shared
Supabase project before testing this feature.

Sign in with a teacher account, then open **Student Messages**. A conversation
appears after a student sends the first message from the website. Replies sent
here are visible to that student in the website conversation.
