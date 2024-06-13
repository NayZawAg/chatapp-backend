class TGroupStarMsgController < ApplicationController
  def create
    @m_user = MUser.find_by(id: @current_user)
    
    if params[:s_channel_id].nil?
      render json: { error: 'Channel ID is missing' }, status: :not_found
    elsif MChannel.find_by(id: params[:s_channel_id]).nil?
      render json: { error: 'Channel not found' }, status: :unprocessable_entity
    else
      @t_group_star_msg = TGroupStarMsg.new
      @t_group_star_msg.userid = @m_user.id
      @t_group_star_msg.groupmsgid = params[:id]
      @t_group_star_msg.save
      
      @m_channel = MChannel.find_by(id: params[:s_channel_id])
      
      render json: { message: 'Group message star successful' }, status: :ok
    end
  end

  def destroy
    @m_user = MUser.find_by(id: @current_user)
    
    if params[:s_channel_id].nil?
      render json: { error: 'Channel ID is missing' }, status: :not_found
    elsif MChannel.find_by(id: params[:s_channel_id]).nil?
      render json: { error: 'Channel not found' }, status: :unprocessable_entity
    else
      TGroupStarMsg.find_by(groupmsgid: params[:id], userid: @m_user.id).destroy
      
      @m_channel = MChannel.find_by(id: params[:s_channel_id])
      render json: { message: 'Delete successful' }, status: :ok
    end
  end
end
