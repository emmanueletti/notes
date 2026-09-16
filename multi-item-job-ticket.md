# Multi item job tickets

## Problem

When dropping off jobs to be done, customers can bring in multiple items to the repair shop. Repair shops currently have to create a job ticket for each item that the customer brings.

By having each item have its own job ticket and number, the items are seperated and hard to track as one entity. This has the following workflow issues:

1. when notifying the customer of job completion, the customer beleives that all their items are completed
2. the repair shop loses track of the fact that the customer brought x amount of items during their visit
3. when creating new job tickets for the items, repair shop has to pick the customer every time

## Approaches

### Option 1: refactor domain model from job tickets to job_tickets -> with one or many multiple items

### Option 2: create a batching system in which we can assign job tickets to belonging to a batch
