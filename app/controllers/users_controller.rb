class UsersController < ApplicationController
  skip_before_action :require_login, only: %i(new create)
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      auto_login(@user)
      redirect_to root_path
    else
      render :new
    end
  end


  def edit
    @user = User.find(current_user)
  end

  def update
    @user = User.find(current_user)
    if @user.update_attributes(user_params)
      redirect_to current_user
    else
      render :edit
    end
  end

  def destroy
    logout
    @user.destroy
    redirect_to root_path
  end

  def show
    @user = User.find(params[:id])
    @saved_timelines = @user.saved_timelines.all
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
