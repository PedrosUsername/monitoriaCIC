# frozen_string_literal: true

require 'rails_helper'

describe UsersController do
  describe '#new' do
    it 'should render the views/users/new.html.haml view' do
      get :new
      expect(response).to render_template(:new)
    end
  end

  describe '#create' do
    before :each do
      @info = {
        name: 'Bernardo Costa Nascimento',
        email: 'bernardoc1104@gmail.com',
        matricula: '140080279',
        cpf: '03638481182',
        rg: '2645178',
        password: '110492',
        password_confirmation: '110492'
      }
      @params = Hash.new
      @params[:user] = @info
    end

    it 'calls the controller method that filters the form input' do
      post :create, params: @params
      users_controller = double('users_controller')
      allow(users_controller).to receive(:user_params).and_return(@params[:user])
    end

    it 'calls the model method that creates the User' do
      ActionController::Parameters.permit_all_parameters = true
      @user = ActionController::Parameters.new(@params[:user])

      expect(User).to receive(:create).with(@user).and_return(User.create(@user))
      post :create, params: @params
    end

    it 'calls the sessions helper method that logs the registered user' do
      expect(assigns(:user)).to eq(@user)
      sessions_helper = double('sessions_helper')
      allow(sessions_helper).to receive(:log_in).with(:user)
      post :create, params: @params
    end

    it 'redirects the registered user to the dashboard' do
      post :create, params: @params

      expect(flash[:notice]).to eq("Registro realizado com sucesso!")
      redirect_to dashboard_path
      expect(subject).to redirect_to('/dashboard')
    end
  end

  describe '#create sad paths' do
    fixtures 'user'

    before :each do
      @info = {
          name: 'Bernardo Costa Nascimento',
          email: 'bernardoc1104@gmail.com',
          matricula: '140080279',
          cpf: '03638481182',
          rg: '2645178',
          password: '110492',
          password_confirmation: '110492'
      }
      @params = Hash.new
      @params[:user] = @info
    end

    describe 'tries to create an invalid user on the database' do
      it 'tries to create a user that is not unique' do
        post :create, params: @params
        expect(flash[:danger]).to include('Matricula has already been taken', 'Email has already been taken',
          'Cpf has already been taken', 'Rg has already been taken')
        redirect_to new_user_path
        expect(subject).to redirect_to('/users/new')
      end
    end

    describe 'tries to create a user by filling the form wrong' do
      before :each do
        @wrong_info = {
          name: '',
          email: '',
          matricula: '',
          cpf: '',
          rg: '',
          password: '',
          password_confirmation: ''
        }

        @params = Hash.new
        @params[:user] = @wrong_info
      end

      it 'leaves the form blank' do
        @params[:user] = @wrong_info
        post :create, params: @params
        expect(flash[:danger]).to include("Name can't be blank", "Email can't be blank", "Cpf can't be blank",
          "Rg can't be blank", "Matricula can't be blank", "Password can't be blank", "Password must be between 6 and 12 characters",
          "Name is too short (minimum is 3 characters)", "Email invalid email format",
          "Cpf is the wrong length (should be 11 characters)", "Cpf only numbers", "Rg is too short (minimum is 7 characters)",
          "Rg only numbers", "Matricula is the wrong length (should be 9 characters)", "Matricula only numbers",
          "Password confirmation must be between 6 and 12 characters")
        redirect_to new_user_path
        expect(subject).to redirect_to('/users/new')
      end
    end
  end

  describe "#update" do
    fixtures 'user'

    before :each do
      @info = {
        name: 'Clarissa e Palos',
        matricula: '140080278',
        cpf: '09646418104',
        rg: '1234567'
      }

      @params = Hash.new
      @params[:user] = @info
      @params[:id] = 2

      @user = user(:some_other_student)
    end

    it 'calls the model method that locates the user' do
      expect(User).to receive(:find_by_email).and_return @user
      put :update, params: @params
    end

    it 'calls the controller method that filters the form input' do
      allow(User).to receive(:find_by_email).and_return @user
      put :update, params: @params
      users_controller = double('users_controller')
      allow(users_controller).to receive(:user_params).and_return(@params[:user])
    end

    it 'calls the model method that performs the update' do
      ActionController::Parameters.permit_all_parameters = true
      @user_params = ActionController::Parameters.new(@params[:user])

      allow(User).to receive(:find_by_email).and_return @user
      expect(@user).to receive(:update_attributes).with(@user_params)
                                                  .and_return(@user.update_attributes(@user_params))

      put :update, params: @params
    end

    it 'redirects the updated user to the dashboard' do
      allow(User).to receive(:find_by_email).and_return @user
      put :update, params: @params

      expect(flash[:notice]).to eq("Cadastro atualizado com sucesso!")
      redirect_to dashboard_path
      expect(subject).to redirect_to ('/dashboard')
    end
  end

  describe '#update sad path' do
    fixtures 'user'

    before :each do
      @info = {
        name: 'Clarissa e Palos',
        matricula: '140080279',
        cpf: '03638481182',
        rg: '2645178'
      }

      @info2 = {
        name: '',
        matricula: '',
        cpf: '',
        rg: ''
      }

      @params = Hash.new
      @params[:id] = 2

      @user = user(:some_other_student)
    end

    it 'tries to update an user with non-unique information' do
      @params[:user] = @info
      ActionController::Parameters.permit_all_parameters = true
      @user_params = ActionController::Parameters.new(@params[:user])

      allow(User).to receive(:find_by_email).and_return @user
      expect(@user).to receive(:update_attributes).with(@user_params)
                                                  .and_return(@user.update_attributes(@user_params))
      put :update, params: @params
      expect(flash[:danger]).to include('Matricula has already been taken', 'Cpf has already been taken',
                                        'Rg has already been taken')
      redirect_to dashboard_path
      expect(subject).to redirect_to ('/dashboard')
    end

    it 'tries to update an user with invalid information' do
      @params[:user] = @info2
      ActionController::Parameters.permit_all_parameters = true
      @user_params = ActionController::Parameters.new(@params[:user])

      allow(User).to receive(:find_by_email).and_return @user
      expect(@user).to receive(:update_attributes).with(@user_params)
                                                  .and_return(@user.update_attributes(@user_params))
      put :update, params: @params
      expect(flash[:danger]).to include(
        "Name can't be blank",
        "Name is too short (minimum is 3 characters)",
        "Cpf can't be blank",
        "Cpf is the wrong length (should be 11 characters)",
        "Cpf only numbers",
        "Rg can't be blank",
        "Rg is too short (minimum is 7 characters)",
        "Rg only numbers",
        "Matricula can't be blank",
        "Matricula is the wrong length (should be 9 characters)",
        "Matricula only numbers"
      )
    end
  end
end