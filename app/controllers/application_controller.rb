class ApplicationController < ActionController::API
  class_attribute :workspace_ides
  include JsonWebToken
  before_action :authenticate_request
  def retrievehome
    @m_workspace = MWorkspace.find_by(id: @current_workspace)
    @m_user = MUser.find_by(id: @current_user)
    @m_users = MUser.joins("INNER JOIN t_user_workspaces ON t_user_workspaces.userid = m_users.id
                          INNER JOIN m_workspaces ON m_workspaces.id = t_user_workspaces.workspaceid")
      .where("m_users.member_status = true and m_workspaces.id = ?", @current_workspace)
    @m_channels = MChannel.select("m_channels.id, channel_name, channel_status, t_user_channels.message_count").joins(
      "INNER JOIN t_user_channels ON t_user_channels.channelid = m_channels.id"
    ).where("(m_channels.m_workspace_id = ? and t_user_channels.userid = ?)", @current_workspace, @current_user).order(id: :asc)
    @m_p_channels = MChannel.select("m_channels.id, channel_name, channel_status")
      .where("(m_channels.channel_status = true and m_channels.m_workspace_id = ?)", @current_workspace).order(id: :asc)
    @direct_msgcounts = []
    @m_users.each do |muser|
      direct_count = TDirectMessage.where(send_user_id: muser.id, receive_user_id:  @current_user, read_status:false)
      thread_count = TDirectThread.joins("INNER JOIN t_direct_messages ON t_direct_messages.id = t_direct_threads.t_direct_message_id")
                                    .where("t_direct_threads.read_status = false AND t_direct_threads.m_user_id = ? AND
                                    ((t_direct_messages.send_user_id = ? AND t_direct_messages.receive_user_id = ?) OR
                                    (t_direct_messages.send_user_id = ? AND t_direct_messages.receive_user_id = ?))",
                                    muser.id, muser.id,  @current_user,  @current_user, muser.id)
      @direct_msgcounts.push(direct_count.size + thread_count.size)
    end
    @all_unread_count = 0
    @m_channels.each do |c|
      @all_unread_count += c.message_count
    end
    @direct_msgcounts.each do |c|
      @all_unread_count +=c
    end
    @m_channelsids = Array.new
    @m_channels.each do|m_channel|
      @m_channelsids.push(m_channel.id)
    end
   
    @retrievehome = { m_users: @m_users, m_channels: @m_channels, direct_msgcounts: @direct_msgcounts, all_unread_count: @all_unread_count,m_channelsids: @m_channelsids }
  
  end
  
  def retrieve_direct_message
    @m_user = MUser.find_by(id: @current_user)
    TDirectMessage.where(send_user_id: params[:id], receive_user_id: @m_user.id, read_status: false).update_all(read_status: true)
    TDirectThread.joins("INNER JOIN t_direct_messages ON t_direct_messages.id = t_direct_threads.t_direct_message_id").where(
      "(t_direct_messages.receive_user_id = ? and t_direct_messages.send_user_id = ? ) AND (t_direct_messages.receive_user_id = ? and t_direct_messages.send_user_id = ? )", @m_user.id,  params[:id],  params[:id], @m_user.id
    ).where.not(m_user_id: @m_user.id, read_status: true).update_all(read_status: true)
    @s_user = MUser.find_by(id: params[:id])
    @t_direct_messages = TDirectMessage.select("name, directmsg, t_direct_messages.id as id, t_direct_messages.created_at  as created_at,
                                          (select count(*) from t_direct_threads where t_direct_threads.t_direct_message_id = t_direct_messages.id) as count")
                                        .joins("INNER JOIN m_users ON m_users.id = t_direct_messages.send_user_id")
                                        .where("(t_direct_messages.receive_user_id = ? AND t_direct_messages.send_user_id = ? )
                                          OR (t_direct_messages.receive_user_id = ? AND t_direct_messages.send_user_id = ? )",
                                          @m_user.id,  params[:id],  params[:id], @m_user.id).order(created_at: :desc)
    @t_direct_messages = @t_direct_messages.reverse
    @temp_direct_star_msgids = TDirectStarMsg.select("directmsgid").where("userid = ?", @m_user.id)
    @t_direct_star_msgids = Array.new
    @temp_direct_star_msgids.each { |r| @t_direct_star_msgids.push(r.directmsgid) }
    @t_direct_message_dates = TDirectMessage.select("distinct DATE(created_at) as created_date")
                                            .where("(t_direct_messages.receive_user_id = ? AND t_direct_messages.send_user_id = ? )
                                            OR (t_direct_messages.receive_user_id = ? AND t_direct_messages.send_user_id = ? )",
                                            @m_user.id,  params[:id],  params[:id], @m_user.id)
    @t_direct_message_datesize = Array.new
    @t_direct_messages.each{|d| @t_direct_message_datesize.push(d.created_at.strftime("%F").to_s)}
   
  end

  def retrieve_direct_thread(direct_message_id)
    @s_user = MUser.find_by(id: @current_user)
        
    @t_direct_message = TDirectMessage.find_by(id: direct_message_id)
    m_userss = MUser.find_by(id: @t_direct_message.send_user_id)
    @send_username = m_userss.name
    @send_user = MUser.find_by(id: @t_direct_message.send_user_id)
    TDirectThread.where.not(m_user_id: @current_user, read_status: false).update_all(read_status: true)

    @t_direct_threads = TDirectThread.select("name, directthreadmsg, t_direct_threads.id as id, t_direct_threads.created_at  as created_at")
                .joins("INNER JOIN t_direct_messages ON t_direct_messages.id = t_direct_threads.t_direct_message_id
                        INNER JOIN m_users ON m_users.id = t_direct_threads.m_user_id")
                .where("t_direct_threads.t_direct_message_id = ?", direct_message_id).order(id: :asc)
    
    @temp_direct_star_thread_msgids = TDirectStarThread.select("directthreadid").where("userid = ?", @current_user)

    @t_direct_star_thread_msgids = Array.new
    @temp_direct_star_thread_msgids.each { |r| @t_direct_star_thread_msgids.push(r.directthreadid) }
  end
  
  def retrieve_group_message
    @m_workspace = MWorkspace.find_by(id: @current_workspace)
    @m_user = MUser.find_by(id: @current_user)
    @s_channel = MChannel.find_by(id: params[:id])
    # @m_channel_users = MUser.joins("INNER JOIN t_user_channels on t_user_channels.userid = m_users.id 
    #                                 INNER JOIN m_channels ON m_channels.id = t_user_channels.channelid")
    #                             .where("m_users.member_status = true AND m_channels.m_workspace_id = ? AND m_channels.id = ?",
    #                             @current_workspace, @s_channel)
    @m_channel_users = MUser.select("m_users.id,m_users.name,m_users.admin,m_users.email,m_users.active_status,m_users.member_status,t_user_channels.created_admin,t_user_channels.created_at")
    .joins("INNER JOIN t_user_channels on t_user_channels.userid = m_users.id
    INNER JOIN m_channels ON m_channels.id = t_user_channels.channelid")
    .where("m_users.member_status = true and m_channels.m_workspace_id = ? and m_channels.id = ?",
    @current_workspace, @s_channel).order("t_user_channels.created_at": :asc)

    TUserChannel.where(channelid: @s_channel, userid:  @current_user).update_all(message_count: 0, unread_channel_message: nil)

    @t_group_messages = TGroupMessage.select("name, groupmsg, t_group_messages.id as id, t_group_messages.created_at as created_at, t_group_messages.m_user_id as send_user_id,
                                            (select count(*) from t_group_threads where t_group_threads.t_group_message_id = t_group_messages.id) as count ")
                                      .joins("INNER JOIN m_users ON m_users.id = t_group_messages.m_user_id")
                                      .where("m_channel_id = ? ", @s_channel).order(created_at: :desc).limit(10)
    
    @t_group_messages = @t_group_messages.reverse
    @temp_group_star_msgids = TGroupStarMsg.select("groupmsgid").where("userid = ?",  @current_user)

    @t_group_star_msgids = Array.new
    @temp_group_star_msgids.each { |r| @t_group_star_msgids.push(r.groupmsgid) }
    @u_count = TUserChannel.where(channelid: @s_channel).count
    # @created_admin = TUserChannel.find_by(channelid: @s_channel)
    @created_admin = TUserChannel.where("created_admin = true and channelid = ?", @s_channel)
    @t_group_message_dates = TGroupMessage.select("distinct DATE(created_at) as created_date").where("m_channel_id = ? ", @s_channel)
    
    @t_group_message_datesize = Array.new
    @t_group_messages.each{|d| @t_group_message_datesize.push(d.created_at.strftime("%F").to_s)}
   
    @retrieve_group_message={
      "s_channel": @s_channel,
      "t_group_messages": @t_group_messages,
      "m_channel_users": @m_channel_users,
      "t_group_star_msgids": @t_group_star_msgids,
      "u_count": @u_count,
      "created_admin": @created_admin,
      "t_group_message_dates": @t_group_message_dates,
      "t_group_message_datesize": @t_group_message_datesize
    }
  end

  def retrieve_group_thread
    @m_workspace = MWorkspace.find_by(id: @current_workspace)
    @m_user = MUser.find_by(id: @current_user)
    @s_channel = MChannel.find_by(id: params[:s_channel_id])

    @m_channel_users = MUser.joins("INNER JOIN t_user_channels on t_user_channels.userid = m_users.id 
                                    INNER JOIN m_channels ON m_channels.id = t_user_channels.channelid")
                                .where("m_users.member_status = true AND m_channels.m_workspace_id = ? AND m_channels.id = ?",
                                @current_workspace, params[:s_channel_id])
                                
    TUserChannel.where(channelid: params[:s_channel_id], userid:  @current_user).update_all(message_count: 0, unread_channel_message: nil)
    
    @t_group_message = TGroupMessage.find_by(id: params[:s_group_message_id])
    @send_user = MUser.find_by(id: @t_group_message.m_user_id)

    @t_group_threads = TGroupThread.select("name, groupthreadmsg, t_group_threads.id as id, t_group_threads.created_at  as created_at, t_group_threads.m_user_id as send_user_id")
                    .joins("INNER JOIN t_group_messages ON t_group_messages.id = t_group_threads.t_group_message_id
                          INNER JOIN m_users ON m_users.id = t_group_threads.m_user_id").where("t_group_threads.t_group_message_id = ?", params[:s_group_message_id]).order(id: :asc)
    
    @temp_group_star_thread_msgids = TGroupStarThread.select("groupthreadid").where("userid = ?", @current_user)

    @t_group_star_thread_msgids = Array.new
    @temp_group_star_thread_msgids.each { |r| @t_group_star_thread_msgids.push(r.groupthreadid) }
    
    @u_count = TUserChannel.where(channelid: params[:s_channel_id]).count
    @retrieveGroupThread= {
      "s_channel": @s_channel,
      "m_channel_users": @m_channel_users,
      "t_group_message": @t_group_message,
      "send_user": @send_user,
      "t_group_threads": @t_group_threads,
      "temp_group_star_thread_msgids": @temp_group_star_thread_msgids,
      "t_group_star_thread_msgids": @t_group_star_thread_msgids,
      "u_count": @u_count
    }
  end
  private
  def authenticate_request
    header = request.headers["Authorization"]
    if header.present?
      header = header.split.last # Remove unnecessary split("").last
      begin
        decoded = jwt_decode(header)
        @current_user = MUser.find(decoded[:user_id])
        @current_workspace = MWorkspace.find(decoded[:workspace_id])
      rescue JWT::DecodeError => e
        render json: { error: "Invalid token" }, status: :unauthorized
      end
    else
      render json: { error: "Authorization header missing" }, status: :unauthorized
    end
  end
end