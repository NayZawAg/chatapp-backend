class TGroupStarMsgController < ApplicationController
  def create
    #check unlogin user
    # checkuser
    @m_user = MUser.find_by(id: @current_user)
    if params[:s_channel_id].nil?
      render json: { error: 'go to home'}
    elsif MChannel.find_by(id: params[:s_channel_id]).nil?
      render json: { error: 'go to home'}
    else
      @t_group_star_msg = TGroupStarMsg.new
      @t_group_star_msg.userid = @m_user.id
      @t_group_star_msg.groupmsgid = params[:id]
      @t_group_star_msg.save
      
      @m_channel = MChannel.find_by(id: params[:s_channel_id])

      render json: { message: 'gp star successfull'}
    end
  end

  def destroy
    #check unlogin user
    # checkuser
    @m_user = MUser.find_by(id: @current_user)
    if params[:s_channel_id].nil?
      render json: { message: 'go to home'}
    elsif MChannel.find_by(id: params[:s_channel_id]).nil?
      render json: { message: 'go to home'}
    else
      TGroupStarMsg.find_by(groupmsgid: params[:id], userid: @m_user.id).destroy
        
      @m_channel = MChannel.find_by(id: params[:s_channel_id])
      render json: { message: 'delete successfull'}
    end
  end
end









