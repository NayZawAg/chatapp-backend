class TDirectReactMsgController < ApplicationController
  def create
    if params[:s_user_id].nil?
     
    else
      existing_reaction = TDirectReactMsg.find_by(directmsgid: params[:message_id], userid: params[:user_id], emoji: params[:emoji])
      if existing_reaction.present?
        TDirectReactMsg.find_by(directmsgid: params[:message_id], userid: params[:user_id], emoji: params[:emoji]).destroy

        render json: { success: 'delete successful'}, status: :ok
      else
        @t_direct_react_msg = TDirectReactMsg.new
        @t_direct_react_msg.directmsgid = params[:message_id]
        @t_direct_react_msg.userid = params[:user_id]
        @t_direct_react_msg.emoji = params[:emoji]
        @t_direct_react_msg.save

        render json: { success: 'react successful'}, status: :ok
      end
    end
  end
end
