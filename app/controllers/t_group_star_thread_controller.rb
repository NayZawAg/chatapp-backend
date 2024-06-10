class TGroupStarThreadController < ApplicationController
  def create
    #check unlogin user
    # checkuser
    @m_user = MUser.find_by(id: @current_user)
    if params[:s_group_message_id].nil?
      unless params[:s_channel_id].nil?
        @m_channel = MChannel.find_by(id: params[:s_channel_id])
        render json: { message: 'go to home'}
      end
    elsif params[:s_channel_id].nil?
      render json: { message: 'go to channel'}
    elsif MChannel.find_by(id: params[:s_channel_id]).nil?
      render json: { message: 'go to home'}
    else
      @t_group_star_thread = TGroupStarThread.new
      @t_group_star_thread.userid = @m_user.id
      @t_group_star_thread.groupthreadid = params[:id]
      @t_group_star_thread.save
      @t_group_message = TGroupMessage.find_by(id: params[:s_group_message_id])
      render json: { message: 'create star success '}
    end
  end
  def destroy
    #check unlogin user
    # checkuser
    @m_user = MUser.find_by(id: @current_user)
    if params[:s_group_message_id].nil?
      unless params[:s_channel_id].nil?
        @m_channel = MChannel.find_by(id: params[:s_channel_id])
        render json: { message: 'go to channel'}
      end
    elsif params[:s_channel_id].nil?
      render json: { message: 'go to home'}
    elsif MChannel.find_by(id: params[:s_channel_id]).nil?
      render json: { message: 'go to home'}
    else
      TGroupStarThread.find_by(groupthreadid: params[:id], userid: @m_user.id).destroy
      @t_group_message = TGroupMessage.find_by(id: params[:s_group_message_id])
      render json: { message: 'delete star success'}
    end
  end
end