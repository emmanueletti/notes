# shopify integration

## mvp rules
- customers created in shopify are not automatically synced to workbench (principle of least knowledge - workbench should only care about customers that are involved in repair flows)
  - customer data imports to to workbench are done on demand:
    - in shopify: when user creates a job ticket for the customer on the shopify customer profile page
    - within app iframe: while creating a job ticket for a customer
      - just like in the native application, user searches for a shopify customer and sets them as the target customer for the new job ticket
  - within app iframe: customers created in workbench are first created in shopify and then saved in workbench
- customers from integration are read only in workbench and need to be edited in shopify (edit link navigates you to the cusstomer edit page in shopify). the webhooks recived will update the record in workbench
  - if webhook delivery is late, users have the option to manually poll for the customers new details (sync button)

### within shopify
- user in shopify is able to install the app via the shopify app marketplace
- user in shopify is able view a special 'connect your shopify account to workbench' that uses username + password auth
  - if user does now have a shopify account, a signup link opens up a new tab to create a new workbench account
- once shopify account is linked to a domain, integration always loads that account within the shoify accounts iframe as we will have a reference between the domain and the repair_shop_id - is this auth handles by shopify_app?
- user is able to create job tickets for a customer
  - we can create our own Current.shopify_repair_shop and Current.shopify_team_member helpers within the integration
- user is able to update customer in shopify and have that change propagate to the application
- user is able to create job tickets for customers that exist in shopify

### within app iframe
- user is able to create job tickets for a customer
- user is able to navigate to link to shopify's customer record fr editing
  - customer record in workbench shows that customer is from shopify integration via an icon indicator. edits must be done there
- user is able to create job tickets for customers that exist in shopify
- user is able to go to all orders for customer

## follow up
- user is able to associate an order with a repair
- user is able to create notes for customer that show up in workbench and shopify


## klaviyos onboarding

- you click install on the shopify application marketplace
- it routes you to klaviyos sign up page
- we need a secure way to handle sign in for pre-existing workbench users
  - we need a way to prove that you own this workbench account AND you own the shopify account being connected

https://www.klaviyo.com/register?sign_up_page=Shopify+Integration&lead_source_detail=Shopify+-+New+Account&full_name=IT%27S+US+STUDIO&company=studio-integration-shop&company_website=studio-integration-shop.myshopify.com&phone=&email=hello%40itsusstudio.com&country_code=US&currency=USD&company_size=0+-+1K&integration_key=shopify&source=shopify_install

- install guide
https://www.youtube.com/watch?v=uXxtE5szb5s

- launch the app as a private install till we validate usefulness. use shopify integration in sales outreach and see if its a differentiator.
- then invest in public app for scale and distribution


