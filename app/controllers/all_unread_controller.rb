# frozen_string_literal: true

class AllUnreadController < ApplicationController
  def show
    # Select unread direct messages from mysql database
    @t_direct_messages = TDirectMessage.select("t_direct_messages.id,t_direct_messages.directmsg,
    t_direct_messages.created_at,m_users.name")
                                       .joins('INNER JOIN m_users ON m_users.id = t_direct_messages.send_user_id')
                                       .where("t_direct_messages.send_user_id=m_users.id and t_direct_messages.read_status=false and
            t_direct_messages.receive_user_id=?", params[:user_id]).order(created_at: :asc)
    # Select unread direct thread messages from mysql database
    @t_direct_threads = TDirectThread.select("t_direct_threads.t_direct_message_id,
    t_direct_threads.directthreadmsg, t_direct_threads.created_at, m_users.name")
                                     .joins("INNER JOIN t_direct_messages ON t_direct_messages.id = t_direct_threads.t_direct_message_id
    INNER JOIN m_users ON m_users.id = t_direct_threads.m_user_id
    INNER JOIN t_user_workspaces ON t_user_workspaces.userid = m_users.id")
                                     .where("t_direct_messages.id=t_direct_threads.t_direct_message_id and t_direct_threads.read_status = false and t_direct_threads.m_user_id=m_users.id
    and t_direct_threads.m_user_id <> ? and t_user_workspaces.workspaceid = ? and (t_direct_messages.receive_user_id = ? or t_direct_messages.send_user_id = ?)", params[:user_id], params[:workspace_id], params[:user_id], params[:user_id]).order(created_at: :asc)
    # Select unread group messages from mysql database
    @temp_user_channelids = TUserChannel.select('unread_channel_message')
                                        .where('message_count > 0 and userid=?', params[:user_id])
    @temp_user_channelthreadids = TUserChannel.select('unread_thread_message')
                                              .where('message_count > 0 and userid=?', params[:user_id])
    @tmp_user_channelids = []
    @t_user_channelids = []
    @temp_user_channelids.each do |u_channel|
      @tmp_user_channelids << u_channel.unread_channel_message.split(',') unless u_channel.unread_channel_message.nil?
    end
    @t_user_channelids = @tmp_user_channelids.flatten
    @tmp_user_channelthreadids = []
    @t_user_channelthreadids = []
    @temp_user_channelthreadids.each do |u_channel_thread|
      unless u_channel_thread.unread_thread_message.nil?
        @tmp_user_channelthreadids << u_channel_thread.unread_thread_message.split(',')
      end
    end
    @t_user_channelthreadids = @tmp_user_channelthreadids.flatten
    @t_group_messages = TGroupMessage.select('t_group_messages.id,t_group_messages.m_channel_id,t_group_messages.groupmsg,t_group_messages.created_at,m_users.name,m_channels.channel_name, (select count(*) from t_group_threads where t_group_threads.t_group_message_id = t_group_messages.id) as count, m_channels.channel_name')
                                     .joins("INNER JOIN m_users ON m_users.id = t_group_messages.m_user_id
    INNER JOIN m_channels ON t_group_messages.m_channel_id=m_channels.id").order(created_at: :asc)
    @t_group_threads = TGroupThread.select("t_group_threads.id,t_group_threads.m_user_id, t_group_threads.groupthreadmsg, t_group_threads.t_group_message_id, t_group_threads.created_at, m_users.name, m_channels.channel_name,
    (select m_channel_id from t_group_messages where t_group_threads.t_group_message_id = t_group_messages.id)")
                                   .joins("INNER JOIN t_group_messages ON t_group_messages.id = t_group_threads.t_group_message_id
            INNER JOIN m_users ON m_users.id = t_group_threads.m_user_id
            INNER JOIN m_channels ON t_group_messages.m_channel_id = m_channels.id").where('t_group_messages.id = t_group_threads.t_group_message_id').order('t_group_threads.created_at ASC')

    retrievehome
  end
end
