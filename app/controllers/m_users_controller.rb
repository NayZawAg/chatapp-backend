class MUsersController < ApplicationController
  
  skip_before_action :authenticate_request, only: [:login_user, :create, :confirm, :confirm_member_signup]
  def login_user
    m_user = MUser.find_by(name: login_params[:name])
    @user = MUser.find_by(id: m_user.id)
    MUser.where(id: @user).update_all(active_status: 1)
    
    m_workspace = MWorkspace.joins("INNER JOIN t_user_workspaces ON t_user_workspaces.workspaceid = m_workspaces.id
                                    INNER JOIN m_users ON m_users.id = t_user_workspaces.userid")
                            .where("m_workspaces.workspace_name = ? and m_users.name = ? ", login_params[:workspace_name],  login_params[:name]).take(1)
    if m_user && m_user.authenticate(login_params[:password]) && m_workspace.size > 0
      t_user_workspace = TUserWorkspace.find_by(userid: m_user.id, workspaceid: m_workspace[0].id)
        if t_user_workspace
          if m_user.member_status == true
          
            token = jwt_encode(user_id: m_user.id,workspace_id: m_workspace[0].id)
             render json: { token: token }, status: :ok
          else
            render json: { error: 'Account Deactivate. Please contact admin.' }, status: :unauthorized
          end
        else
          render json: { error: 'Invalid name/password combination' }, status: :not_found
        end
    else
      render json: { error: 'Invalid name/password combination' }, status: :unprocessable_entity
    end
  end

  def logout
    @user = MUser.find_by(id: @current_user)
    MUser.where(id: @user).update_all(active_status: 0)
    render json: {message: 'Sign Out Successfully'}
  end

  def confirm
    # Check login user
    # checkloginuser
    @m_workspace = MWorkspace.find_by(id: params[:workspaceid])
    @m_channel = MChannel.find_by(id: params[:channelid])
    @m_user = MUser.new
    @m_user.email = params[:email]
    @m_user.remember_digest = @m_workspace.workspace_name
    @m_user.profile_image = @m_channel.channel_name
    
  end

  def create
    #check login user
    # checkloginuser

    @m_user = MUser.new(user_params)

    @m_workspace = MWorkspace.new
    @m_workspace.workspace_name = @m_user.remember_digest

    @m_channel = MChannel.new
    @m_channel.channel_name = @m_user.profile_image
    @m_channel.channel_status = 1

    @m_user.member_status = 1

    status = true

    # @t_workspace = MWorkspace.find_by(id: session[:invite_workspaceid])
    @t_workspace = MWorkspace.find_by(id: params[:invite_workspaceid])
    if status &&  @m_user.save
      MUser.where(id: @m_user.id).update_all(remember_digest: nil, profile_image: nil)
    else 
      status = false
    end

    if(@t_workspace.nil?)
      if status && @m_workspace.save
      
      else 
        status = false
      end
    else
      @m_workspace = @t_workspace
    end

    @t_user_workspace = TUserWorkspace.new
    @t_user_workspace.userid = @m_user.id
    @t_user_workspace.workspaceid = @m_workspace.id

    if status && @t_user_workspace.save

    else 
      status = false
    end

    @t_user_channel = TUserChannel.new
    
    @t_channel = MChannel.find_by(channel_name: @m_channel.channel_name, m_workspace_id: @m_workspace.id)
    
    if(@t_channel.nil?)
      @t_user_channel.created_admin = 1
      @m_channel.m_workspace_id = @m_workspace.id

      if status && @m_channel.save
      else 
        status = false
      end
    else
      @t_user_channel.created_admin = 0
      @m_channel = @t_channel
    end

    @t_user_channel.message_count = 0
    @t_user_channel.unread_channel_message = 0
    @t_user_channel.userid = @m_user.id
    @t_user_channel.channelid = @m_channel.id

    if status && @t_user_channel.save
    else 
      status = false
    end

    if(status)
      render json: { message: "Signup Complete." }, status: :ok
    else
      render json: { error: "Signup Failed." }, status: :unprocessable_entity
    end
  end

  def confirm_member_signup
    @m_user = MUser.new(user_params)
    @m_workspace = MWorkspace.new
    @m_workspace.workspace_name = @m_user.remember_digest
    @m_channel = MChannel.new
    @m_channel.channel_name = @m_user.profile_image
    @m_channel.channel_status = true
    @m_user.member_status = true
    status = true
    @t_workspace = MWorkspace.find_by(id: invite_workspace_id_param[:invite_workspaceid])
    if status &&  @m_user.save
      MUser.where(id: @m_user.id).update_all(remember_digest: nil, profile_image: nil)
    else
      status = false
    end
    if(@t_workspace.nil?)
      if status && @m_workspace.save
      else
        status = false
      end
    else
      @m_workspace = @t_workspace
    end
    @t_user_workspace = TUserWorkspace.new
    @t_user_workspace.userid = @m_user.id
    @t_user_workspace.workspaceid = @m_workspace.id
    if status && @t_user_workspace.save
    else
      status = false
    end
    @t_user_channel = TUserChannel.new
    @t_channel = MChannel.find_by(channel_name: @m_channel.channel_name, m_workspace_id: @m_workspace.id)
    if(@t_channel.nil?)
      @t_user_channel.created_admin = true
      @m_channel.m_workspace_id = @m_workspace.id
      if status && @m_channel.save
      else
        status = false
      end
    else
      @t_user_channel.created_admin = false
      @m_channel = @t_channel
    end
    @t_user_channel.message_count = 0
    @t_user_channel.unread_channel_message = 0
    @t_user_channel.userid = @m_user.id
    @t_user_channel.channelid = @m_channel.id
    if status && @t_user_channel.save
    else
      status = false
    end
    if(status)
      render json: { message: "Signup Complete."}, status: :ok
    else
      render json: { error: "Signup Failed."}, status: :unprocessable_entity
    end
  end
  def show
    retrieve_direct_message
    retrievehome
    
  end
  def show_home
    @m_workspace = MWorkspace.find_by(id: @current_workspace)
    @m_user = MUser.find_by(id: @current_user)
    if @m_user
      retrievehome
    end
  end
 
  def mainPage
    @m_workspace = MWorkspace.find_by(id: @current_workspace)
    @m_user = MUser.find_by(id: @current_user)
    retrievehome
  end

  def update
    #check unlogin user
    # checkuser
    @user = @current_user.id
    @m_user = MUser.new(user_params)
    password = params[:m_user][:password]
    password_confirmation = params[:m_user][:password_confirmation]
    if password == "" || password.nil?
      render json: { error: "Password can't be blank." }, status: :unprocessable_entity
    elsif password_confirmation == "" || password_confirmation.nil?
      render json: { error: "Confirm Password can't be blank." }, status: :unprocessable_entity
    elsif password != password_confirmation
      render json: { error: "Password and Confirmation Password does not match." }, status: :unprocessable_entity
    else
      MUser.where(id: @user).update_all(password_digest: @m_user.password_digest)
      render json: { message: "Change Password Successful." }, status: :ok
    end
  end
private
  def user_params
    params.require(:m_user).permit(:name, :email, :password,
    :password_confirmation, :profile_image, :remember_digest, :admin)
  end
  def login_params
    params.require(:user).permit(
      :name,
      :password,
      :workspace_name
  )
  end

  def invite_workspace_id_param
    params.require(:workspace_id).permit(:invite_workspaceid)
  end
  
end