require 'base64'
require 'digest'
require 'aws-sdk-s3'
require 'mime/types'

class GroupMessageController < ApplicationController
  def show
    # Check unlogin user
    # checkuser
    @m_user = MUser.find_by(id: @current_user)
    @m_workspace = MWorkspace.find_by(id: @current_workspace)
  
    if params[:s_channel_id].nil?
      render json: { message: 'channel not found!' }
      return
    elsif MChannel.find_by(id: params[:s_channel_id]).nil?
      render json: { message: 'user not found!' }
      return
    end
  
    file_records = []
  
    # Check if file parameters exist and process each file
    if params[:files].present?
      params[:files].each do |file|
        image_mime = file[:mime]
        image_data = decode(file[:data])
  
        # Validate MIME type
        if MIME::Types[image_mime].empty?
          render json: { error: 'Unsupported Content-Type' }, status: :unsupported_media_type
          return
        end
  
        file_extension = extension(image_mime)
        file_url = put_s3(image_data, file_extension, image_mime)
        file_records << { file: file_url, mime_type: image_mime, extension: file_extension, m_user_id: @m_user.id }
      end
    end
  
    @t_group_message = TGroupMessage.new(
      groupmsg: params[:message],
      m_user_id: @m_user.id,
      m_channel_id: params[:s_channel_id]
    )
  
    if @t_group_message.save
      file_records.each do |file_record|
        file_record[:t_group_message_id] = @t_group_message.id
        TGroupMsgFile.create(file_record)
      end
  
      mention_name = params[:mention_name]
  
      unless mention_name.nil?
        mention_name.each do |u_mention|
          u_mention[0] = ''
          @mention_user = MUser.find_by(name: u_mention)
          @t_group_mention_msg = TGroupMentionMsg.new(
            userid: @mention_user.id,
            groupmsgid: @t_group_message.id
          )
          @t_group_mention_msg.save
        end
      end
  
      @t_user_channels = TUserChannel.where(channelid: params[:s_channel_id])
  
      @t_user_channels.each do |u_channel|
        if u_channel.userid != @m_user.id
          u_channel.message_count = u_channel.message_count + 1
          temp_msgid = ""
  
          unless u_channel.unread_channel_message.nil?
            u_channel.unread_channel_message.split(",").each do |u_message|
              temp_msgid += u_message
              temp_msgid += ","
            end
          end
  
          temp_msgid += @t_group_message.id.to_s
          u_channel.unread_channel_message = temp_msgid
  
          TUserChannel.where(id: u_channel.id).update_all(message_count: u_channel.message_count, unread_channel_message: u_channel.unread_channel_message )
        end
      end
  
      MUser.joins("INNER JOIN t_user_channels ON t_user_channels.userid = m_users.id 
                   INNER JOIN m_channels ON m_channels.id = t_user_channels.channelid")
           .where("m_channels.m_workspace_id = ? AND m_channels.id = ?",
                  @m_workspace.id, params[:s_channel_id])
           .where.not("m_users.id = ?", @m_user.id)
           .update_all(remember_digest: "1")
  
      @m_channel_users = MUser.joins("INNER JOIN t_user_channels ON t_user_channels.userid = m_users.id 
                                       INNER JOIN m_channels ON m_channels.id = t_user_channels.channelid")
                               .where("m_users.member_status = true AND m_channels.m_workspace_id = ? AND m_channels.id = ?",
                                      @m_workspace.id, params[:s_channel_id])
                               .where.not("m_users.id = ?", @m_user.id)
                
      @m_channel_users.each do |user|
        MUser.where(id: user.id).update_all(remember_digest: "1")
      end
  
      @m_channel = MChannel.find_by(id: params[:s_channel_id])
      render json: {"t_group_message": @t_group_message, "mention": mention_name, "t_group_msg_file": file_records}
    end 
  end
  

  def showthread
    # Check unlogin user
    # checkuser
    @m_user = MUser.find_by(id: @current_user)
    @m_workspace = MWorkspace.find_by(id: @current_workspace)
  
    if params[:s_group_message_id].nil?
      unless params[:s_channel_id].nil?
        @m_channel = MChannel.find_by(id: params[:s_channel_id])
      end
    elsif params[:s_channel_id].nil?
      render json: { message: 'Channel not found!' }
    elsif MChannel.find_by(id: params[:s_channel_id]).nil?
      render json: { message: 'Channel not found!' }
    else
      @t_group_message = TGroupMessage.find_by(id: params[:s_group_message_id])
  
      if @t_group_message.nil?
        unless params[:s_channel_id].nil?
          @m_channel = MChannel.find_by(id: params[:s_channel_id])
        else
          render json: { message: 'Channel not found!' }
        end
      else
        file_records = []
  
        # Check if file parameter exists
        if params[:files].present?
          params[:files].each do |file|
            image_mime = file[:mime]
            image_data = decode(file[:data])
  
            # Validate MIME type
            if MIME::Types[image_mime].empty?
              render json: { error: 'Unsupported Content-Type' }, status: :unsupported_media_type
              return
            end
  
            file_extension = extension(image_mime)
            file_url = put_s3(image_data, file_extension, image_mime)
            file_records << { file: file_url, mime_type: image_mime, extension: file_extension, m_user_id: @m_user.id }
          end
        end
  
        @t_group_thread = TGroupThread.new(
          groupthreadmsg: params[:message],
          t_group_message_id: params[:s_group_message_id],
          m_user_id: @m_user.id
        )
  
        if @t_group_thread.save
          file_records.each do |file_record|
            file_record[:t_group_thread_id] = @t_group_thread.id
            TGroupThreadMsgFile.create(file_record)
          end
  
          mention_name = params[:mention_name]
  
          unless mention_name.nil?
            mention_name.each do |u_mention|
              u_mention[0] = ''
              @mention_user = MUser.find_by(name: u_mention)
              @t_group_mention_thread = TGroupMentionThread.new(
                userid: @mention_user.id,
                groupthreadid: @t_group_thread.id
              )
              @t_group_mention_thread.save
            end
          end
  
          @t_user_channels = TUserChannel.where(channelid: params[:s_channel_id])
  
          @t_user_channels.each do |u_channel|
            if u_channel.userid != @m_user.id
              u_channel.message_count += 1
              temp_msgid = ""
  
              unless u_channel.unread_channel_message.nil?
                arr_msgid = u_channel.unread_channel_message.split(",")
                unless arr_msgid.include? params[:s_group_message_id].to_s
                  u_channel.unread_channel_message.split(",").each do |u_message|
                    temp_msgid += u_message
                    temp_msgid += ","
                  end
                  u_channel.unread_channel_message = temp_msgid
                end
              end
  
              temp_msgid += params[:s_group_message_id].to_s
  
              TUserChannel.where(id: u_channel.id).update_all(
                message_count: u_channel.message_count,
                unread_channel_message: u_channel.unread_channel_message
              )
            end
          end
  
          MUser.joins("INNER JOIN t_user_channels ON t_user_channels.userid = m_users.id")
               .where("t_user_channels.id = ?", params[:s_channel_id])
               .where.not("m_users.id = ?", @m_user.id)
               .update_all(remember_digest: "1")
  
          @m_channel_users = MUser.joins("INNER JOIN t_user_channels ON t_user_channels.userid = m_users.id
                                          INNER JOIN m_channels ON m_channels.id = t_user_channels.channelid")
                                  .where("m_users.member_status = true AND m_channels.m_workspace_id = ? AND m_channels.id = ?",
                                         @m_workspace.id, params[:s_channel_id])
                                  .where.not("m_users.id = ?", @m_user.id)
  
          @m_channel_users.each do |user|
            MUser.where(id: user.id).update_all(remember_digest: "1")
          end 
  
          @m_channel = MChannel.find_by(id: params[:s_channel_id])
  
          render json: {
            "t_group_thread": @t_group_thread,
            "mention": mention_name,
            "t_group_msg_file": file_records
          }
        end
      end
    end
  end
  

  def deletemsg
    # Check unlogin user
    # checkuser
    @m_user = MUser.find_by(id: @current_user)
    if params[:s_channel_id].nil?
      render json: { error: 'Your Mistake' }
    elsif MChannel.find_by(id: params[:s_channel_id]).nil?
      render json: { error: 'Go to Channel!' }
    else
      gpthread = TGroupThread.select("id").where(t_group_message_id: params[:id])
      gpthread.each do |gpthread|
        TGroupStarThread.where(groupthreadid: gpthread.id).destroy_all
        TGroupMentionThread.where(groupthreadid: gpthread.id).destroy_all
        TGroupThread.find_by(id: gpthread.id).destroy
      end

      TGroupStarMsg.where(groupmsgid: params[:id]).destroy_all
      TGroupMentionMsg.where(groupmsgid: params[:id]).destroy_all
      TGroupMessage.find_by(id: params[:id]).delete

      @t_user_channels = TUserChannel.where(channelid: params[:s_channel_id])
      @t_user_channels.each do |u_channel|
        if u_channel.userid != @m_user.id
          u_channel.message_count -= (gpthread.size + 1)
          if u_channel.message_count < 0
            TUserChannel.where(id: u_channel.id).update_all(message_count: 0)
          else
            TUserChannel.where(id: u_channel.id).update_all(message_count: u_channel.message_count)
          end
        end
      end

      @m_channel = MChannel.find_by(id: params[:s_channel_id])
      render json: { message: 'Delete successful' }
    end
  end

  def deletethread
    # Check unlogin user
    # checkuser
    @m_user = MUser.find_by(id: @current_user)
    if params[:s_group_message_id].nil?
      unless params[:s_channel_id].nil?
        @m_channel = MChannel.find_by(id: params[:s_channel_id])
        render json: { message: 'Wrong Channel Id' }
      end
    elsif params[:s_channel_id].nil?
      render json: { message: 'Your Mistake' }
    elsif MChannel.find_by(id: params[:s_channel_id]).nil?
      render json: { message: 'Go to Home' }
    else
      TGroupStarThread.where(groupthreadid: params[:id]).destroy_all
      TGroupMentionThread.where(groupthreadid: params[:id]).destroy_all
      TGroupThread.find_by(id: params[:id]).destroy

      @t_user_channels = TUserChannel.where(channelid: params[:s_channel_id])
      @t_user_channels.each do |u_channel|
        if u_channel.userid != @m_user.id
          u_channel.message_count -= 1
          if u_channel.message_count < 0
            TUserChannel.where(id: u_channel.id).update_all(message_count: u_channel.message_count)
          else
            TUserChannel.where(id: u_channel.id).update_all(message_count: u_channel.message_count)
          end
        end
      end

      @t_group_message = TGroupMessage.find_by(id: params[:s_group_message_id])
      render json: { message: 'Good Job!!!!!' }
    end
  end

  private

  def decode(data)
    Base64.decode64(data)
  end

  def extension(mime_type)
    mime = MIME::Types[mime_type].first
    raise "Unsupported Content-Type" unless mime
    mime.extensions.first ? ".#{mime.extensions.first}" : raise("Unknown extension for MIME type")
  end

  def put_s3(data, extension, mime_type)
    file_name = Digest::SHA1.hexdigest(data) + extension
    s3 = Aws::S3::Resource.new
    bucket = s3.bucket("rails-blog-minio")
    obj = bucket.object("files/#{file_name}")

    obj.put(
      acl: "public-read",
      body: data,
      content_type: mime_type,
      content_disposition: "inline"
    )

    obj.public_url
  end
end
