
class TGroupMessagesController < ApplicationController
  def show
    
    if params[:s_channel_id].nil?
      redirect_to home_url
    elsif MChannel.find_by(id: params[:s_channel_id]).nil?
      redirect_to home_url
    else
      params[:s_group_message_id] =  params[:id]
      retrieve_group_thread
      retrievehome
    end
  end
end



