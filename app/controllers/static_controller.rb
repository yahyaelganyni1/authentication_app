class StaticController < ApplicationController
  def home
    render json: { message: "Hello World!" }
  end
end
