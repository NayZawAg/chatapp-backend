class TGroupReactMsgController < ApplicationController
  def create
    #check unlogin user
    # checkuser
    @m_user = MUser.find_by(id: @current_user)
    if params[:s_channel_id].nil?
      render json: { error: 'go to home'}, status: :ok
    elsif MChannel.find_by(id: params[:s_channel_id]).nil?
      render json: { error: 'go to home'}, status: :ok
    else
      existing_reaction = TGroupReactMsg.find_by(groupmsgid: params[:message_id], userid: @m_user.id, emoji: params[:emoji])
      if existing_reaction.present?
        TGroupReactMsg.find_by(groupmsgid: params[:message_id], userid: @m_user.id, emoji: params[:emoji]).destroy

        render json: { message: 'delete successful'}, status: :ok
      else
        @t_group_react_msg = TGroupReactMsg.new
        @t_group_react_msg.groupmsgid = params[:message_id]
        @t_group_react_msg.userid = @m_user.id
        @t_group_react_msg.emoji = params[:emoji]
        @t_group_react_msg.save

        render json: { message: 'react successful'}, status: :ok
      end
    end
  end
end
