class MentionListsController < ApplicationController
  def show
    @t_group_messages = TGroupMessage.select("t_group_messages.id, t_group_messages.groupmsg, t_group_messages.created_at, m_users.name, m_channels.channel_name, m_users_profile_images.image_url as profile_image, ARRAY_AGG(distinct t_group_msg_files.file) as file_urls, ARRAY_AGG(distinct t_group_msg_files.file_name) as file_names")
                                    .joins("INNER JOIN t_group_mention_msgs ON t_group_messages.id = t_group_mention_msgs.groupmsgid
                                            INNER JOIN m_users ON t_group_messages.m_user_id = m_users.id
                                            INNER JOIN m_channels ON t_group_messages.m_channel_id = m_channels.id")
                                    .joins("LEFT  JOIN t_group_msg_files ON t_group_msg_files.t_group_message_id = t_group_messages.id")
                                    .joins("LEFT  JOIN m_users_profile_images ON m_users_profile_images.m_user_id = m_users.id")
                                    .where("t_group_mention_msgs.userid = ?", params[:user_id])
                                    .group("t_group_messages.id, t_group_messages.groupmsg, t_group_messages.created_at, m_users.name, m_channels.channel_name, m_users_profile_images.image_url")
                                    .order(id: :asc)

    @t_group_threads = TGroupThread.select("t_group_threads.id, t_group_threads.groupthreadmsg, t_group_threads.created_at, m_users.name, m_channels.channel_name, m_users_profile_images.image_url as profile_image, ARRAY_AGG(distinct t_group_thread_msg_files.file) as file_urls, ARRAY_AGG(distinct t_group_thread_msg_files.file_name) as file_names")
                                  .joins("INNER JOIN t_group_mention_threads ON t_group_threads.id = t_group_mention_threads.groupthreadid
                                          INNER JOIN t_group_messages ON t_group_messages.id = t_group_threads.t_group_message_id
                                          INNER JOIN m_users ON m_users.id = t_group_threads.m_user_id
                                          INNER JOIN m_channels ON t_group_messages.m_channel_id = m_channels.id")
                                  .joins("LEFT  JOIN t_group_thread_msg_files ON t_group_thread_msg_files.t_group_thread_id = t_group_threads.id")
                                  .joins("LEFT  JOIN m_users_profile_images ON m_users_profile_images.m_user_id = m_users.id")
                                  .where("t_group_mention_threads.userid = ?", params[:user_id])
                                  .group("t_group_threads.id, t_group_threads.groupthreadmsg, t_group_threads.created_at, m_users.name, m_channels.channel_name, m_users_profile_images.image_url")
                                  .order(id: :asc)

    @temp_group_star_msgids = TGroupStarMsg.select("groupmsgid").where("userid = ?", params[:user_id])

    @t_group_star_msgids = @temp_group_star_msgids.pluck(:groupmsgid)

    @temp_group_star_thread_msgids = TGroupStarThread.select("groupthreadid").where("userid = ?", params[:user_id])

    @t_group_star_thread_msgids = @temp_group_star_thread_msgids.pluck(:groupthreadid)
  end
end
