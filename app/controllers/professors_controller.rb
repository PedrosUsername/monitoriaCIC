class ProfessorsController < ApplicationController
  def index 
    #@CicList = ["Shacon", "Alchieri", "Díbio", "Genaina", "Celio"]
    @professor = Professor.all
  end

  def new ; end

  def create
    @professor = Professor.create(professor_params)

    if !@professor.errors.any?
      flash[:notice] = "Registro realizado com sucesso!"
      log_in(@professor)
      redirect_to dashboard_path
    else
      flash[:danger] = @professor.errors.full_messages
      redirect_to new_professor_path
    end
  end
  def identityconfirmation
    @professor = Professor.where(:name => params[:professor][:name])[0]
    # Acrescente um ponto de exclamação em deliver_now para renderizar as mensagens de erro...
    ProfessorMailer.with(professor: @professor).key_email.deliver_now
  end

  def confirm_email
    professor = Professor.find_by_confirm_token(params[:id])
    if professor
      professor.email_activate
      flash[:success] = "Bem vindo! E-mail confirmado."
      redirect_to new_session_url
    else
      flash[:error] = "Erro. Professor inexistente"
      redirect_to root_url
    end
  end

  def update
    @professor = Professor.find_by_email(session[:user_id])
    @professor.update_attributes(professor_params)

    if !@professor.errors.any?
      flash[:notice] = "Cadastro atualizado com sucesso!"
    elsif
      flash[:danger] = @professor.errors.full_messages
    end

    redirect_to dashboard_path
  end

  protected

  def professor_params
    params.require(:professor).permit(:id, :name, :username, :email, :role, :password, :password_confirmation)
  end
end