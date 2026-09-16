# Custom project thoughts

## Domain modeling

Project
- a project is associated to a customer record
- has a quote
- has multiple stages
- a project can have many Stages
  - workbench has an opinionated set of stages that are non-configurable
  - if shops complain, we can do the migration later to support configurable stages

Stage
- inquiry
- design
- quote
- sourcing
- production
- quality_assurance
- delivery
- delivered (terminal stage - collect feedback and reviews)

- each stage has its own set of views and concerns
- promoting a project to the next stage closes the previous view and creates a new set of concerns
- a user can re-open the previous stages view to see all that done in that stage

- i envision a kanban view of all the projects and stages at once (except for terminal delivered stage which is an index table view to reduce clutter)
- within each project, we see a dropdown view of all the stages and their concerns, each one can be unfurled to see what was done in that stage

