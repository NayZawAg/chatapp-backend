class TDirectStarMsgController < ApplicationController
  def create
    if params[:s_user_id].present?
      @t_direct_star_msg = TDirectStarMsg.new
      @t_direct_star_msg.userid = params[:user_id]
      @t_direct_star_msg.directmsgid = params[:id]
      @t_direct_star_msg.save

      @s_user = MUser.find_by(id: params[:s_user_id])

      render json: { success: 'Star successful' }, status: :ok
    end
  end

  def destroy
    TDirectStarMsg.find_by(directmsgid: params[:id], userid: @current_user).destroy
    render json: { success: 'Unstar successful' }, status: :ok
  end
end
