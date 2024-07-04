class TDirectReactThreadController < ApplicationController
  def create
    #check unlogin user
    # checkuser

    if params[:s_direct_message_id].nil?
      unless params[:s_user_id].nil?
        @user = MUser.find_by(id: params[:s_user_id])
        render json: { error: 'go to user'}, status: :ok
      end
    elsif params[:s_user_id].nil?
      render json: { error: 'check user'}, status: :ok
    else
      existing_reaction = TDirectReactThread.find_by(directthreadid: params[:thread_id], userid: params[:user_id], emoji: params[:emoji])
      if existing_reaction.present?
        TDirectReactThread.find_by(directthreadid: params[:thread_id], userid: params[:user_id], emoji: params[:emoji]).destroy

        render json: { success: 'delete successful'}, status: :ok
      else
        @t_direct_react_thread = TDirectReactThread.new
        @t_direct_react_thread.directthreadid = params[:thread_id]
        @t_direct_react_thread.userid = params[:user_id]
        @t_direct_react_thread.emoji = params[:emoji]
        @t_direct_react_thread.save
  
        render json: { success: 'react successful'}, status: :ok
      end
    end
  end
end
