class StaticController < ApplicationController
  def home

    # If the user is logged in, redirect to the user's dashboard.
    if logged_in?
      redirect_to dashboard_path
    end
  end
end
