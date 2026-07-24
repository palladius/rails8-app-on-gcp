# Specification: User Association and Commenter Names for Comments

## Overview
Currently, comments are strictly text blocks. This track will allow comments to have an author attribution—either by explicitly associating them with a registered `User` account, or by allowing a graceful fallback to a `commenter_name` string (e.g., for anonymous guests). This resolves circularity issues while providing an elegant way to display "Riccardo: This is going to be an epic workshop! 🚀".

## Functional Requirements
1. **Database Schema:** 
   - Add an optional `user_id` foreign key to the `comments` table.
   - Add a `commenter_name` string column to the `comments` table.
2. **Model Logic (`Comment`):**
   - The `user` association should be optional.
   - Implement a method (e.g., `author_name`) that returns the associated User's name if present, otherwise returns `commenter_name`.
   - If `commenter_name` is blank and no User is associated, it should default to "Anonymous".
3. **User Interface:**
   - Update the Comment form to include an optional 'Name' input field for anonymous users (hide if logged in).
   - Update the Comment partials to display the author's name in bold before the comment text (e.g., `**Riccardo:** This is cool`).
4. **Seeding:**
   - Update `seeds.rb` to generate comments utilizing the new `commenter_name` or `user_id` fields appropriately.

## Acceptance Criteria
- [ ] Users can post a comment without being logged in by providing an optional name.
- [ ] If no name is provided and the user is not logged in, the comment displays as from "Anonymous".
- [ ] If the user is logged in, their user account is associated with the comment automatically.
- [ ] The comment author's name is rendered in bold in the UI.

## Out of Scope
- Creating user authentication or login flows (assuming standard Rails/Devise or similar is handled elsewhere).
- Avatars or profile pictures.
