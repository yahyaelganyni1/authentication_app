# create rails7 authentication API with a cookie store

### this app is for intermediate rails developers

_a rails7 tutorial to create a simple authentication API with a cookie store_

## creating a new rails7 app

lets start by creating a new rails7 app

```bash
rails new rails7-authentication --database=postgresql
```

note here we are not using the `--api` flag because we want to use the `ActionDispatch::Session::CookieStore` middleware

and what that will do is enable us to use the `session` object in our controllers

### navigating to the app directory

```bash
cd rails7-authentication
```

## **now lets start step by step**

## 1- add 2 gems to the gem file

```ruby
gem 'bcrypt'
gem 'rack-cors'
```

the `bcrypt` gem will be used to hash the password, and the `rack-cors` gem will be used to enable cross origin requests from the frontend app to the backend app (the frontend app will be on a different port)

## 2-create 2 files `cors.rb` and `session_store.rb` in `config/initializers`

```console
    touch config/initializers/session_store.rb
```

```console
    touch config/initializers/cors.rb
```

## 3- configuration the cors.rb

```ruby
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "localhost:3000"
    resource "*",
             headers: :any,
             methods: [:get, :post, :put, :patch, :delete, :options, :head],
             credentials: true
  end
end
```

now lets explain the code

the `Rails.application.config.middleware.insert_before 0, Rack::Cors do` is a middleware that will be executed before the request is sent to the server

the `allow do` is a method that will allow the request to be sent to the server

the `origins "localhost:3000"` is the origin of the request

the `resource "*"` is the resource that will be allowed to be accessed and by the `*` it means all the resources

the `headers: :any` is the headers that will be allowed to be sent to the server, by `:any` it means all the headers

the `methods: [:get, :post, :put, :patch, :delete, :options, :head]` is the methods that will be allowed to be sent to the server

the `credentials: true` is the credentials that will be allowed to be sent to the server

## 4- configuration the session_store.rb

```ruby
Rails.application.config.session_store :cookie_store, key: "_authentication_app", domain: "localhost:3000"
```

lets explain

the `Rails.application.config.session_store :cookie_store` is the session store that will be used

and the `key: "_authentication_app"` is the key that will be used to encrypt the session and it usually is the name of the app in this case `rails7-authentication` and we add the `_` to the beginning of the name

and the `domain: "localhost:3000"` is the domain that will be used to store the session and it is the same domain that we used in the `cors.rb` file and it is the domain of the frontend app that will be on a different port from the backend app

## 5- create a user model

lets create a user model with email and password

```console
rails g model User email password_digest
```

and then we add the migration to the database by running

```console
rails db:migrate
```

that will create a user model with email and password_digest

`password_digest` is used to store an encrypted password in the database

## 6- edit the user model

```ruby
class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true
end
```

what happened here is that we added the `has_secure_password` method to the user model and that will add the `password` and `password_confirmation` to the user model

and the `validates :email, presence: true, uniqueness: true` is a validation that will make sure that the email is present and unique

## 7- add the sessions to the routes

```ruby
Rails.application.routes.draw do
  resources :sessions, only: [:create]
end
```

## 8- create a session and registration controller

```console
touch app/controllers/regisration_controller.rb
```

```console
 touch app/controllers/session_controller.rb
```

## 9- fill the registration and session controller

### 9.1- registration controller

```ruby
class RegistrationsController < ApplicationController
  def create
    user = User.create!(
      email: params["user"]["email"],
      password: params["user"]["password"],
      password_confirmation: params["user"]["password_confirmation"],
    )
    if user
      session[:user_id] = user.id
      render json: {
               status: :created,
               user: user,
             }
    else
      render json: { status: 500 }
    end
  end
end
```

lets explain the code

the `user = User.create!(email: params["user"]["email"], password: params["user"]["password"], password_confirmation: params["user"]["password_confirmation"])` is the user that will be created

the `if user` is a condition that will check if the user is created or not

the `session[:user_id] = user.id` is the session that will be created and it will be stored in the cookie

the `render json: { status: :created, user: user }` is the response that will be sent to the frontend app

the `else render json: { status: 500 }` is the response that will be sent to the frontend app if the user is not created and `500` is the status code for internal server error

### 9.2- session controller

```ruby
class SessionController < ApplicationController
  def create
    user = User
      .find_by(email: params["user"]["email"])
      .try(:authenticate, params["user"]["password"])

    if user
      session[:user_id] = user.id
      render json: {
               status: :created,
               logged_in: true,
               user: user,
             }
    else
      render json: { status: 401, message: "Invalid email or password" }
    end
  end
end
```

### lets explain what is happening here

the `def create` is a method that will be used to create a session for the user

the `user = User.find_by(email: params["user"]["email"]).try(:authenticate, params["user"]["password"])` is a method that will find the user by the email and authenticate the user by the password

the `if user` is a condition that will check if the user is found or not

the `session[:user_id] = user.id` is a method that will store the user id in the session

and if the user authenticated successfully then it will render a json response with the status, logged_in, and the user

if not then it will render a json response with the status and the message that the email or password is invalid

## 10- lets test the session and the registration

**note** we will be using curl to test the session and the registration

**_curl_**
is a command line tool that used to send requests to the server

### 10.1- lets start the server

```console
rails s
```

### 10.2- lets test the session

open a new tap in the terminal and run the following command

```console
curl --header "Content-Type: application/json" \
  --request POST \
  --data '{"user":{"email":"test@test.com","password":"password"}}' \
    http://localhost:3000/registrations
```

#### and you will get a response like this

```json
{
  "status": "created",
  "user": {
    "id": 1,
    "email": "test@test.com",
    "password_digest": "$2a$12$hJz6em6H4pngrPaWLV74EOYYG7QPzfbJCZlsmODjTBwEWoj6kp99W",
    "created_at": "2022-10-31T21:32:48.065Z",
    "updated_at": "2022-10-31T21:32:48.065Z"
  }
}
```

### 10.3- lets test the session

```console
curl --header "Content-Type: application/json" \
  --request POST \
  --data '{"user":{"email":"test@test.com","password":"password"}}' \
    http://localhost:3000/sessions
```

#### and you will get a response like this

```json
{
  "status": "created",
  "logged_in": true,
  "user": {
    "id": 1,
    "email": "test@test.com",
    "password_digest": "$2a$12$hJz6em6H4pngrPaWLV74EOYYG7QPzfbJCZlsmODjTBwEWoj6kp99W",
    "created_at": "2022-10-31T21:32:48.065Z",
    "updated_at": "2022-10-31T21:32:48.065Z"
  }
}
```

**note** that the password_digest is the encrypted password and it will be different for you because it is encrypted and same thing for the created_at and updated_at and also it will not be formatted it will be squished together in the terminal

## 11- lets add the login and logout to the routes

```ruby
Rails.application.routes.draw do
  resources :sessions, only: [:create]
  delete :logout, to: "sessions#logout"
  get :logged_in, to: "sessions#logged_in"
end
```

## 12- lets add the login and logout to the session controller

### 12.1- lets add something to the application controller

```ruby
class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token
end
```

**what happened here?**

we added the `skip_before_action :verify_authenticity_token` to the application controller and that will skip the authenticity token verification

### 12.2- before we add the login and logout to the session controller lets create a concern that will be used to check if the user is logged in or not

```console
touch app/controllers/concerns/current_user_concern.rb
```

**what is a concern?**
a concern is a module that will be used to add methods to the controller

### 12.3- lets edit the current_user_concern.rb

```ruby
module CurrentUserConcerns
  extend ActiveSupport::Concern

  included do
    before_action :set_current_user
  end

  def set_current_user
    if session[:user_id]
      @current_user = User.find(session[:user_id])
    end
  end
end
```

**what is happening here?**

the `module CurrentUserConcern` is a module that will check if the user is logged in or not

the `extend ActiveSupport::Concern` is a method that will be used to add the methods to the controller that will include the concern module

the included do is a method that will be used to add the `before_action :set_current_user` to the controller that will include the concern module

the `def set_current_user` is a method that will be used to set the current user if the user is logged in or not

the `if session[:user_id]` is a condition that will check if the user is logged in or not

the `@current_user = User.find(session[:user_id])` is a method that will find the user by the user id that is stored in the session

### 12.4- lets add the concern to the session controller

```ruby
class SessionsController < ApplicationController
  include CurrentUserConcerns
  ......
end
```

### 12.5- then we can create the login and logout methods

```ruby
class SessionsController < ApplicationController
 ........

  def logged_in
    if @current_user
      render json: {
               logged_in: true,
               user: @current_user,
             }
    else
      render json: {
               logged_in: false,
             }
    end
  end

  def logout
    reset_session
    render json: { status: 200, logged_out: true }
  end
end
```

**what is happening here?**

the `def logged_in` is a method that will check if the user is logged in or not by checking the `@current_user` and if the user is logged in then it will render a json response with the status, logged_in, and the user and if not then it will render a json response with the status and the logged_in false

the `def logout` is a method that will reset the session and render a json response with the status and the logged_out true and that will log the user out and reset the session

## 13- final step is to make it work in production

in the `config/intializers/session_store.rb` file we need to add if condition to check if the environment is production or not

```ruby
if Rails.env = "production"
  Rails.application.config.session_store :cookie_store, key: "_authentication_app", domain: "your-frontend-domain"
else
  Rails.application.config.session_store :cookie_store, key: "_authentication_app"
end
```

**what is happening here?**

if it is production then it will use the cookie_store and the key will be `_authentication_app` and the domain will be `your-frontend-domain` and if it is not production then it will use the cookie_store and the key will be `_authentication_app`

## finished

**congratulations you have finished the authentication tutorial and now you have a full authentication system with the registration, login, and logout and you can use it in your projects and you can also add more features to it like forgot password, reset password, and more**

if you liked the tutorial please give it a star 🌟
