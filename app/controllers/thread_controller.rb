class ThreadController < ApplicationController
  def show
    @t_direct_messages = TDirectMessage.select("distinct t_direct_messages.id, m_users.name, receiver.name as receiver_name , t_direct_messages.directmsg, t_direct_messages.created_at, t_direct_messages.send_user_id, t_direct_messages.receive_user_id, m_users_profile_images.image_url as profile_image,
                                                       ARRAY_AGG(distinct t_direct_message_files.file) as file_urls, ARRAY_AGG(distinct t_direct_message_files.file_name) as file_names, MAX(t_direct_threads.created_at) as last_thread_created_at")
                                              .joins("INNER JOIN t_direct_threads ON t_direct_threads.t_direct_message_id = t_direct_messages.id
                                                     INNER JOIN m_users ON m_users.id = t_direct_messages.send_user_id
                                                     INNER JOIN m_users as receiver ON receiver.id = t_direct_messages.receive_user_id")
                                              .joins("LEFT JOIN m_users_profile_images ON m_users_profile_images.m_user_id = m_users.id")
                                              .joins("LEFT JOIN t_direct_message_files ON t_direct_message_files.t_direct_message_id = t_direct_messages.id")
                                              .where("t_direct_threads.t_direct_message_id = t_direct_messages.id AND t_direct_messages.send_user_id = ? OR t_direct_threads.m_user_id = ?", @current_user.id, @current_user.id)
                                              .group("t_direct_messages.id, m_users.name, t_direct_messages.directmsg, t_direct_messages.created_at, t_direct_messages.send_user_id, t_direct_messages.receive_user_id, m_users_profile_images.image_url, receiver.name")
                                              .order("last_thread_created_at DESC")

    @t_direct_threads = TDirectThread.select("t_direct_threads.id as id, t_direct_threads.m_user_id, m_users.name, t_direct_threads.directthreadmsg, t_direct_threads.t_direct_message_id, t_direct_threads.created_at, m_users_profile_images.image_url as profile_image,
                                                    ARRAY_AGG(t_direct_thread_msg_files.file) as file_urls, ARRAY_AGG(t_direct_thread_msg_files.file_name) as file_names")
                                           .joins("JOIN m_users ON t_direct_threads.m_user_id = m_users.id
                                                   JOIN t_direct_messages ON t_direct_threads.t_direct_message_id = t_direct_messages.id")
                                           .joins("LEFT JOIN m_users_profile_images ON m_users_profile_images.m_user_id = m_users.id")
                                           .joins("LEFT JOIN t_direct_thread_msg_files ON t_direct_thread_msg_files.t_direct_thread_id = t_direct_threads.id")
                                           .where("t_direct_messages.send_user_id = ? OR t_direct_messages.receive_user_id = ?", @current_user, @current_user)
                                           .group("t_direct_threads.id, m_users.name,t_direct_threads.m_user_id, t_direct_threads.directthreadmsg, t_direct_threads.t_direct_message_id, t_direct_threads.created_at, m_users_profile_images.image_url")
                                           .order(id: :asc)
                                           
    @t_group_messages = TGroupMessage.select("distinct m_users.name, t_group_messages.groupmsg,t_group_messages.m_user_id as m_user_id, t_group_messages.id as id, t_group_threads.t_group_message_id, t_group_messages.m_channel_id as channel_id, m_channels.channel_status as channel_status, m_users_profile_images.image_url as profile_image,
                                           t_group_messages.created_at as created_at, m_channels.channel_name as channel_name, ARRAY_AGG(distinct t_group_msg_files.file) as file_urls, ARRAY_AGG(distinct t_group_msg_files.file_name) as file_names, ARRAY_AGG(DISTINCT m_channel_users.name) AS channel_users, MAX(t_group_threads.created_at) as last_thread_created_at")
                                          .joins("INNER JOIN m_channels ON m_channels.id = t_group_messages.m_channel_id
                                                   INNER JOIN m_users ON m_users.id = t_group_messages.m_user_id
                                                   INNER JOIN t_group_threads ON t_group_threads.t_group_message_id = t_group_messages.id")
                                          .joins("LEFT JOIN t_group_msg_files ON t_group_msg_files.t_group_message_id = t_group_messages.id")
                                          .joins("LEFT JOIN m_users_profile_images ON m_users_profile_images.m_user_id = m_users.id")
                                          .joins("INNER JOIN t_user_channels ON t_user_channels.channelid = t_group_messages.m_channel_id")
                                          .joins("INNER JOIN m_users AS m_channel_users ON m_channel_users.id = t_user_channels.userid")
                                          .where("t_group_threads.t_group_message_id = t_group_messages.id AND t_group_messages.m_user_id = ? OR t_group_threads.m_user_id = ?", @current_user, @current_user)
                                          .group("m_users.name, t_group_messages.groupmsg, t_group_messages.m_user_id, t_group_messages.id, m_users_profile_images.image_url, t_group_threads.t_group_message_id, t_group_messages.created_at, m_channels.channel_name, m_channels.channel_status")
                                          .order("last_thread_created_at DESC")
                                          
    @t_group_threads = TGroupThread.select("m_users.name, m_channels.channel_name, t_group_threads.groupthreadmsg,t_group_threads.m_user_id, t_group_threads.id, t_group_threads.t_group_message_id as t_group_message_id, t_group_threads.created_at, m_users_profile_images.image_url as profile_image ,ARRAY_AGG(t_group_thread_msg_files.file) as file_urls, ARRAY_AGG(t_group_thread_msg_files.file_name) as file_names")
                                          .joins("INNER JOIN t_group_messages ON t_group_messages.id = t_group_threads.t_group_message_id
                                                 INNER JOIN m_users ON t_group_threads.m_user_id = m_users.id
                                                 INNER JOIN m_channels ON t_group_messages.m_channel_id = m_channels.id")
                                          .joins("LEFT JOIN m_users_profile_images ON m_users_profile_images.m_user_id = m_users.id")
                                          .joins("LEFT JOIN t_group_thread_msg_files ON t_group_thread_msg_files.t_group_thread_id = t_group_threads.id")
                                          .where("t_group_threads.t_group_message_id = t_group_messages.id OR t_group_messages.m_user_id = ? OR t_group_threads.m_user_id = ?", @current_user, @current_user)
                                          .group("m_users.name, m_channels.channel_name,t_group_threads.m_user_id, t_group_threads.groupthreadmsg, t_group_threads.id, m_users_profile_images.image_url, t_group_threads.t_group_message_id, t_group_threads.created_at")
                                          .order(created_at: :asc)
                                          
    @t_direct_star_msgids = TDirectStarMsg.select("directmsgid").where("userid = ?", @current_user).pluck(:directmsgid)
    @t_direct_star_thread_msgids = TDirectStarThread.select("directthreadid").where("userid = ?", @current_user).pluck(:directthreadid)
    @t_group_star_msgids = TGroupStarMsg.select("groupmsgid").where("userid = ?", @current_user).pluck(:groupmsgid)
    @t_group_star_thread_msgids = TGroupStarThread.select("groupthreadid").where("userid = ?", @current_user).pluck(:groupthreadid)
    
  end

end