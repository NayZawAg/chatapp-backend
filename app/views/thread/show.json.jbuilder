json.t_direct_messages @t_direct_messages do |t_direct_message|
  json.id t_direct_message.id
  json.name t_direct_message.name
  json.receiver_id t_direct_message.receive_user_id
  json.sender_id t_direct_message.send_user_id
  json.file_urls t_direct_message.file_urls
  json.directmsg t_direct_message.directmsg
  json.created_at t_direct_message.created_at
end

json.t_direct_threads @t_direct_threads do |t_direct_thread|
  json.id t_direct_thread.id
  json.name t_direct_thread.name
  json.file_urls t_direct_thread.file_urls
  json.directthreadmsg t_direct_thread.directthreadmsg
  json.t_direct_message_id t_direct_thread.t_direct_message_id
  json.sender_id t_direct_thread.m_user_id
  json.created_at t_direct_thread.created_at
end

json.t_group_messages @t_group_messages do |t_group_message|
  json.id t_group_message.id
  json.name t_group_message.name
  json.file_urls t_group_message.file_urls
  json.channel_id t_group_message.channel_id
  json.channel_status t_group_message.channel_status
  json.channel_name t_group_message.channel_name
  json.groupmsg t_group_message.groupmsg
  json.m_user_id t_group_message.m_user_id
  json.created_at t_group_message.created_at
end

json.t_group_threads @t_group_threads do |t_group_thread|
  json.id t_group_thread.id
  json.name t_group_thread.name
  json.file_urls t_group_thread.file_urls
  json.channel_name t_group_thread.channel_name
  json.groupthreadmsg t_group_thread.groupthreadmsg
  json.t_group_message_id t_group_thread.t_group_message_id
  json.m_user_id t_group_thread.m_user_id
  json.created_at t_group_thread.created_at
end

json.t_direct_star_thread_msgids @t_direct_star_thread_msgids
json.t_direct_star_msgids @t_direct_star_msgids
json.t_group_star_msgids @t_group_star_msgids
json.t_group_star_thread_msgids @t_group_star_thread_msgids
