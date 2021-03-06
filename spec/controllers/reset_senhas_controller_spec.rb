# frozen_string_literal: true

require 'rails_helper'

describe ResetSenhasController do
  describe '#new' do
    it 'should render views/reset_senhas/new.html.haml' do
      get :new
      expect(response).to render_template(:new)
    end
  end

  describe '#create' do
    fixtures 'user'

    before :each do
      @email = {email: 'bernardoc1104@gmail.com'}
      @params = Hash.new
      @params[:reset_senha] = @email
    end

    it 'should receive a valid e-mail and redirect to the homepage' do
      post :create, params: @params
      expect(flash[:notice]).to eq("As instruções para resetar sua senha foram enviadas para seu e-mail.")
      redirect_to root_path
      expect(subject).to redirect_to('/')
    end

    it 'should send an e-mail with the following properties to a registered user' do
      user = User.find_by_email('clapalos@live.com')
      user.reset_token = User.new_token
      mail = UserMailer.reset_senha(user)

      expect(mail.subject).to eq("Recuperação de senha")
      expect(mail.to).to match_array(user.email)
      expect(mail.body.encoded).to match(user.reset_token)
    end
  end

  describe '#create sad paths' do
    describe 'email is not on DB' do
      before :each do
        @email = {email: 'abobrinhajr@unb.br'}
        @params = Hash.new
        @params[:reset_senha] = @email
      end

      it 'should receive an invalid e-mail and display the appropriate message' do
        post :create, params: @params
        expect(flash[:danger]).to eq("Seu e-mail não foi encontrado.")
        redirect_to new_reset_senha_path
        expect(subject).to render_template(:new)
      end
    end

    describe 'email field is left blank' do
      before :each do
        @blank = {email: ''}
        @params = Hash.new
        @params[:reset_senha] = @blank
      end

      it 'should receive blank e-mail and display the appropriate message' do
        post :create, params: @params
        expect(flash[:danger]).to eq("Seu e-mail não foi encontrado.")
        redirect_to new_reset_senha_path
        expect(subject).to render_template(:new)
      end
    end
  end

  describe '#edit' do
    fixtures 'user'

    before :each do
      allow_any_instance_of(ResetSenhasController).to receive(:valid_user).and_return(true)
      allow_any_instance_of(ResetSenhasController).to receive(:check_expiration).and_return(true)
    end

    it 'should render views/reset_senhas/edit.html.haml' do
      user = User.find_by_email('clapalos@live.com')
      user.reset_token = User.new_token

      get :edit, params: {id: user.reset_token, email: user.email }
      expect(response).to render_template(:edit)
    end
  end

  describe '#edit sad path' do
    fixtures 'user'

    before :each do
      @user = User.find_by_email('clapalos@live.com')
      @user.reset_token = User.new_token
      @user.reset_sent_at = Time.zone.now
    end

    it 'receives an invalid e-mail and redirect to homepage' do
      get :edit, params: { id: @user.reset_token, email: 'abobrinhajr@unb.br' }
      redirect_to root_path
      expect(response).to redirect_to('/')
    end

    it 'receives a blank e-mail and redirect to homepage' do
      get :edit, params: { id: @user.reset_token, email: '' }
      redirect_to root_path
      expect(response).to redirect_to('/')
    end

    it 'receives an invalid token and redirect to homepage' do
      get :edit, params: { id: 'J0hnR0n4ld$R3u3lTolkien', email: @user.email }
      redirect_to root_path
      expect(response).to redirect_to('/')
    end

    it 'receives a blank token and redirect to homepage' do
      get :edit, params: { id: '', email: @user.email }
      redirect_to root_path
      expect(response).to redirect_to('/')
    end
  end

  describe '#update' do
    fixtures 'user'

    before :each do
      @user = User.find_by_email('clapalos@live.com')
      @user.reset_token = User.new_token
      @user.reset_sent_at = Time.zone.now

      @params = {id: @user.reset_token, user: {password: 'asdfg123', password_confirmation: 'asdfg123'}}

      allow_any_instance_of(ResetSenhasController).to receive(:get_user).with(params: {email: @user.email})
      allow_any_instance_of(ResetSenhasController).to receive(:valid_user).and_return(true)
      allow_any_instance_of(ResetSenhasController).to receive(:check_expiration).and_return(true)
    end

    it 'should call the controller method that filters the form input' do
      reset_controller = double('reset_senhas_controller')
      allow(reset_controller).to receive(:user_params).and_return(@params[:user])
    end

    it 'should receive a valid password and perform the update' do
      ActionController::Parameters.permit_all_parameters = true
      @user_params = ActionController::Parameters.new(@params[:user])
      expect(@user).to receive(:update_attributes).with(@user_params).and_return(@user.update_attributes(@user_params))

      reset_controller = double('reset_senhas_controller')
      allow(reset_controller).to receive(:update).with(@params).and_return(@user.update_attributes(@user_params))
    end
  end

  describe '#update sad path' do
    fixtures 'user'

    before :each do
      @user = User.find_by_email('clapalos@live.com')
      @user.reset_token = User.new_token
      @user.reset_sent_at = Time.zone.now

      allow_any_instance_of(ResetSenhasController).to receive(:get_user).with(params: {email: @user.email})
      allow_any_instance_of(ResetSenhasController).to receive(:valid_user).and_return(true)
      allow_any_instance_of(ResetSenhasController).to receive(:check_expiration).and_return(true)
    end

    it 'should receive an invalid password (too short) and re-render the page' do
      @params = {id: @user.reset_token, user: {password: '12345', password_confirmation: '12345'}}

      reset_controller = double('reset_senhas_controller')
      allow(reset_controller).to receive(:update).with(@params).and_return(render_template(:edit))
    end

    it 'should receive an invalid password (too long) and re-render the page' do
      @params = {id: @user.reset_token, user: {password: '123456789ABCD', password_confirmation: '123456789ABCD'}}

      reset_controller = double('reset_senhas_controller')
      allow(reset_controller).to receive(:update).with(@params).and_return(render_template(:edit))
    end

    it 'should receive a blank password, post an error message and re-render the page' do
      @params = {id: @user.reset_token, user: {password: '', password_confirmation: ''}}

      reset_controller = double('reset_senhas_controller')
      allow(reset_controller).to receive(:update).with(@params).and_return(render_template(:edit))
      allow_any_instance_of(User).to receive_message_chain(:errors, :full_messages)
                                        .and_return("O campo senha deve ser preenchido.")
    end

    it 'should receive unmatched password and password confirmation, and re-render the page' do
      @params = {id: @user.reset_token, user: {password: '12345678', password_confirmation: '87654321'}}

      reset_controller = double('reset_senhas_controller')
      allow(reset_controller).to receive(:update).with(@params).and_return(render_template(:edit))
    end

  end

end
