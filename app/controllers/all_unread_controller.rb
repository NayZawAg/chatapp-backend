class AllUnreadController < ApplicationController
    def show
       
      @m_user = MUser.find_by(id: params[:user_id])
      @t_direct_messages=TDirectMessage.select("t_direct_messages.id,t_direct_messages.directmsg,t_direct_messages.created_at,m_users.name")
          .joins("INNER JOIN m_users ON m_users.id = t_direct_messages.send_user_id")
          .where("t_direct_messages.send_user_id=m_users.id AND t_direct_messages.read_status=false AND
              t_direct_messages.receive_user_id=?",@m_user) 
  
      #Select unread direct thread messages from mysql database        
      @t_direct_threads=TDirectThread.select("t_direct_threads.t_direct_message_id,
              t_direct_threads.directthreadmsg,t_direct_threads.created_at,m_users.name")
          .joins("INNER JOIN t_direct_messages ON t_direct_messages.id = t_direct_threads.t_direct_message_id
              INNER JOIN m_users ON m_users.id = t_direct_threads.m_user_id")
          .where("t_direct_messages.id=t_direct_threads.t_direct_message_id AND t_direct_threads.read_status=false AND t_direct_threads.m_user_id=m_users.id 
              AND t_direct_threads.m_user_id <> ?",@m_user)
  
      #Select unread group messages from mysql database        
      @temp_user_channelids=TUserChannel.select("unread_channel_message").where("message_count > 0 and userid=?",@m_user)
  
      @t_user_channelids = Array.new
      @temp_user_channelids.each do |u_channel|
          unless u_channel.unread_channel_message.nil?
              @t_user_channelids = u_channel.unread_channel_message.split(",")
          end
      end
  
      @t_group_messages = TGroupMessage.select("t_group_messages.id,t_group_messages.groupmsg,t_group_messages.created_at,m_users.name,m_channels.channel_name, (select count(*) from t_group_threads where t_group_threads.t_group_message_id = t_group_messages.id) as count, m_channels.channel_name")
      .joins("INNER JOIN m_users ON m_users.id = t_group_messages.m_user_id
      INNER JOIN m_channels ON t_group_messages.m_channel_id=m_channels.id")
  
      
      #call from ApplicationController for retrieve home data
      retrievehome
  
        #TDirectMessage.where(receive_user_id: session[:user_id], read_status: 0).update_all(read_status: 1)
    end
  end
  