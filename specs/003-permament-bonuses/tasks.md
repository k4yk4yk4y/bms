# Tasks: Permanent Bonus Management

This document outlines the tasks required to implement the Permanent Bonus Management feature.

## Phase 1: Setup

- **T001**: [X] Create a database migration to add the `permanent_bonuses` table with `project_id` and `bonus_id` foreign keys.
  - **File**: `db/migrate/YYYYMMDDHHMMSS_create_permanent_bonuses.rb`

## Phase 2: Foundational

- **T002**: [X] Create the `PermanentBonus` model with `belongs_to :project` and `belongs_to :bonus` associations.
  - **File**: `app/models/permanent_bonus.rb`
- **T003**: [X] Create the ActiveAdmin resource for `PermanentBonus`.
  - **File**: `app/admin/permanent_bonuses.rb`
- **T004**: [X] Create the `Admin::PermanentBonusesController`.
  - **File**: `app/controllers/admin/permanent_bonuses_controller.rb`

## Phase 3: User Story 1 - View Permanent Bonuses

- **Goal**: As a Project Manager or Admin, I want to see a list of all permanent bonuses configured for a specific project.
- **Independent Test**: Navigate to the project's permanent bonus section and verify the list of bonuses is displayed correctly.

- **T005**: [X] [US1] Implement the `index` action in `Admin::PermanentBonusesController` to fetch and display permanent bonuses for a project.
- **T006**: [X] [US1] Create the `index` view to render the list of permanent bonuses.
- **T007**: [X] [US1] Implement the `show` action in `Admin::PermanentBonusesController` to fetch the full details of a bonus.
- **T008**: [X] [US1] Create a partial for the `show` modal view to display the full bonus details.

--- CHECKPOINT: User Story 1 complete ---

## Phase 4: User Story 2 - Add a Permanent Bonus

- **Goal**: As an Admin, I want to add a new permanent bonus to a project by selecting it from a list of existing bonuses.
- **Independent Test**: Add a new bonus and verify it appears in the list.

- **T009**: [X] [US2] Implement the `new` and `create` actions in `Admin::PermanentBonusesController`.
- **T010**: [X] [US2] Create the `_form` partial for the "Add" form, including a dropdown to select from existing bonuses.
- **T011**: [X] [US2] Implement an endpoint to list all bonuses for the dropdown.

--- CHECKPOINT: User Story 2 complete ---

## Phase 5: User Story 3 - Delete a Permanent Bonus

- **Goal**: As an Admin, I want to delete a permanent bonus from a project.
- **Independent Test**: Delete a bonus and verify it is removed from the list.

- **T012**: [X] [US3] Implement the `destroy` action in `Admin::PermanentBonusesController`.
  - **File**: `app/controllers/admin/permanent_bonuses_controller.rb`

--- CHECKPOINT: User Story 3 complete ---

## Phase 6: User Story 4 - Manage Empty Bonus Cards

- **Goal**: As a Project Manager, I want to be able to see when a permanent bonus card is no longer linked to a real bonus, so that I can either re-link it to a new bonus or delete it.
- **Independent Test**: Delete a source bonus and verify the card becomes empty and can be re-linked or deleted.

- **T013**: [X] [US4] Implement logic in the `index` view to identify and display empty/unlinked cards.
  - **File**: `app/views/admin/permanent_bonuses/index.html.erb`
- **T014**: [X] [US4] Implement the `edit` and `update` actions in `Admin::PermanentBonusesController` to allow re-linking an empty card.
  - **File**: `app/controllers/admin/permanent_bonuses_controller.rb`

--- CHECKPOINT: User Story 4 complete ---

## Phase 7: Polish & Integration

- **T015**: [X] [P] Add model tests for `PermanentBonus`.
  - **File**: `spec/models/permanent_bonus_spec.rb`
- **T016**: [X] [P] Add controller tests for `Admin::PermanentBonusesController`.
  - **File**: `spec/controllers/admin/permanent_bonuses_controller_spec.rb`
- **T017**: [X] [P] Add request/integration tests for the permanent bonus management workflow.
  - **File**: `spec/requests/admin/permanent_bonuses_spec.rb`
- **T018**: [X] Review and refine the UI for the new feature.

## Dependencies

- **US1** (View) must be completed before any other user story.
- **US2** (Add), **US3** (Delete), and **US4** (Manage Empty) can be implemented in any order after US1.

## Parallel Execution

- Within Phase 7, the test tasks (T015, T016, T017) can be worked on in parallel.

## Implementation Strategy

The suggested implementation strategy is to follow the phases in order, starting with the foundational setup and then implementing each user story as an independent increment. The MVP (Minimum Viable Product) is the completion of User Story 1, which provides the core viewing functionality.
