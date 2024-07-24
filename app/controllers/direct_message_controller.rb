require 'base64'
require 'digest'
require 'aws-sdk-s3'
require 'mime/types'

class DirectMessageController < ApplicationController
  def index
    @t_direct_message = TDirectMessage.all
    render json: @t_direct_message
  end

  def show
    if params[:s_user_id].nil?
      render json: { error: 'Receive user not exists!' }, status: :bad_request
      return
    end

    file_records = []

    if params[:files].present?
      params[:files].each do |file|
        image_mime = file[:mime]
        image_data = decode(file[:data])
        file_name = file[:file_name]

        if MIME::Types[image_mime].empty?
          render json: { error: 'Unsupported Content-Type' }, status: :unsupported_media_type
          return
        end
        folder_name_for_dm= "direct_message_files"
        file_extension = extension(image_mime)
        file_url = put_s3(image_data, file_extension, image_mime, folder_name_for_dm )
        file_records << { file: file_url, mime_type: image_mime, extension: file_extension, m_user_id: params[:user_id], file_name: file_name }
      end
    end

    @t_direct_message = TDirectMessage.new(
      directmsg: params[:message],
      send_user_id: params[:user_id],
      receive_user_id: params[:s_user_id],
      read_status: 0,
      draft_message_status: params[:draft_message_status]
    )

    if @t_direct_message.save
      file_records.each do |file_record|
        file_record[:t_direct_message_id] = @t_direct_message.id
        file_record[:diirectmsgid] = @t_direct_message.id
        TDirectMessageFile.create(file_record)
      end

      @sender_name = MUser.find_by(id: params[:user_id]).name
      
      if MUsersProfileImage.find_by(m_user_id: params[:user_id]).present?
        @sender_profile_image = MUsersProfileImage.find_by(m_user_id: params[:user_id]).image_url
      end

      
      MUser.where(id: params[:s_user_id]).update_all(remember_digest: "1")
      ActionCable.server.broadcast("direct_message_channel", {
        message: @t_direct_message,
        files: file_records,
        sender_name: @sender_name,
        profile_image: @sender_profile_image
      })

      render json: {
        t_direct_message: @t_direct_message,
        t_file_upload: file_records,
        sender_name: @sender_name
      }, status: :created
    else
      render json: @t_direct_message.errors, status: :unprocessable_entity
    end
  end

  def showthread
    if params[:s_direct_message_id].nil?
      if params[:s_user_id].present?
        @user = MUser.find_by(id: params[:s_user_id])
        render json: @user
      end
    elsif params[:s_user_id].nil?
      render json: { error: 'Receive user not existed!' }
    else
      @t_direct_message = TDirectMessage.find_by(id: params[:s_direct_message_id])

      if @t_direct_message.nil?
        if params[:s_user_id].present?
          @user = MUser.find_by(id: params[:s_user_id])
          render json: @t_direct_message
        end
      else
        file_records = []

        if params[:files].present?
          params[:files].each do |file|
            image_mime = file[:mime]
            image_data = decode(file[:data])
            file_name = file[:file_name]

            if MIME::Types[image_mime].empty?
              render json: { error: 'Unsupported Content-Type' }, status: :unsupported_media_type
              return
            end
            folder_name_for_dt = "direct_thread_files"
            file_extension = extension(image_mime)
            file_url = put_s3(image_data, file_extension, image_mime, folder_name_for_dt)
            file_records << { file: file_url, mime_type: image_mime, extension: file_extension, m_user_id: params[:user_id], file_name: file_name }
          end
        end

        @t_direct_thread = TDirectThread.new(
          directthreadmsg: params[:message],
          t_direct_message_id: params[:s_direct_message_id],
          m_user_id: params[:user_id],
          read_status: 0,
          draft_message_status: params[:draft_message_status],
        )

        if @t_direct_thread.save
          file_records.each do |file_record|
            file_record[:t_direct_thread_id] = @t_direct_thread.id
            file_record[:direct_thread_id] = @t_direct_thread.id
            TDirectThreadMsgFile.create(file_record)
          end

          @sender_name = MUser.find_by(id: params[:user_id]).name
          
          if MUsersProfileImage.find_by(m_user_id: params[:user_id]).present?
            @sender_profile_image = MUsersProfileImage.find_by(m_user_id: params[:user_id]).image_url
          end

          MUser.where(id: params[:s_user_id]).update_all(remember_digest: "1")

          ActionCable.server.broadcast("direct_thread_message_channel", {
            message: @t_direct_thread,
            files: file_records,
            sender_name: @sender_name,
            profile_image: @sender_profile_image
          })

          render json: {
            t_direct_thread_message: @t_direct_thread,
            t_thread_file_upload: file_records
          }, status: :created
        else
          render json: @t_direct_thread.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def deletemsg
    directthreads = TDirectThread.where(t_direct_message_id: params[:id])
    directthreads.each do |directthread|
      TDirectThreadMsgFile.where(direct_thread_id: directthread.id).each do |file|
        delete_from_s3(file.file)
      end
      TDirectStarThread.where(directthreadid: directthread.id).destroy_all
      TDirectReactThread.where(directthreadid: directthread.id).destroy_all
      directthread.destroy
    end
   
    TDirectMessageFile.where(t_direct_message_id: params[:id]).each do |file|
      delete_from_s3(file.file)
    end

    TDirectStarMsg.where(directmsgid: params[:id]).destroy_all
    TDirectReactMsg.where(directmsgid: params[:id]).destroy_all

    @delete_msg = TDirectMessage.find_by(id: params[:id]).destroy
    ActionCable.server.broadcast("direct_message_channel", {
        delete_msg: @delete_msg
          })
    render json: { success: 'Successfully Delete Messages' }
  end

  

  def deletethread
    if params[:s_direct_message_id].nil?
      unless params[:s_user_id].nil?
        @user = MUser.find_by(id: params[:s_user_id])
        if @user.nil?
          render json: { error: 'User not found' }, status: :not_found
        else
          render json: { error: 'Direct Message Not found' }, status: :not_found
        end
        return
      end
    elsif params[:s_user_id].nil?
      render json: { error: 'User not found' }, status: :not_found
      return
    else
      ActiveRecord::Base.transaction do
        TDirectThreadMsgFile.where(direct_thread_id: params[:id]).each do |file|
          delete_from_s3(file.file)
        end
        TDirectStarThread.where(directthreadid: params[:id]).destroy_all
        TDirectReactThread.where(directthreadid: params[:id]).destroy_all

        @delete_thread_msg = TDirectThread.find_by(id: params[:id])
        if @delete_thread_msg.nil?
          render json: { error: 'Direct thread not found' }, status: :not_found
          return
        else
          @delete_thread_msg.destroy
        end
        
        
        TDirectThreadMsgFile.where(direct_thread_id: params[:id]).destroy_all
  
        @t_direct_message = TDirectMessage.find_by(id: session[:s_direct_message_id])
        @delete_msg = TDirectMessage.find_by(id: params[:id])
        if @delete_msg.nil?
          Rails.logger.error "Direct message with id #{params[:id]} not found."
        else
          @delete_msg.destroy
        end
  
        ActionCable.server.broadcast("direct_thread_message_channel", {
          delete_msg_thread: @delete_thread_msg
        })
  
        render json: { success: 'Successfully deleted messages' }, status: :ok
      rescue => e
        render json: { error: e.message }, status: :internal_server_error
      end
    end
  end
  

  def showMessage
    @second_user = params[:second_user]
    retrieve_direct_message(@second_user)
  end

  # direct message edit
  def edit
    @t_direct_message = TDirectMessage.find_by(id: params[:id])
    render json: { message: @t_direct_message }, status: :ok
  end

  # direct message update
  def update
    t_direct_message = TDirectMessage.where(id: params[:id]).first
    message = params[:message]
    TDirectMessage.where(id: t_direct_message.id).update_all(directmsg: message)

    @update_direct_message = TDirectMessage.where(id: params[:id]).first

    ActionCable.server.broadcast("direct_message_channel", {
      update_message: @update_direct_message,
      sender_name: @current_user.name
    })

    render json: { message: 'direct message updated successfully.'}, status: :ok
  end

  # direct message thread edit
  def edit_thread
    @t_direct_thread = TDirectThread.find_by(id: params[:id])
    render json: { message: @t_direct_thread }, status: :ok
  end

  # direct message thread update
  def update_thread
    t_direct_thread = TDirectThread.where(id: params[:id]).first
    message = params[:message]
    TDirectThread.where(id: t_direct_thread.id).update_all(directthreadmsg: message)

    @update_direct_thread = TDirectThread.where(id: params[:id]).first

    if MUsersProfileImage.find_by(m_user_id: @current_user.id).present?
      @sender_profile_image = MUsersProfileImage.find_by(m_user_id: @current_user.id).image_url
    end

    ActionCable.server.broadcast("direct_thread_message_channel", {
      update_thread_message: @update_direct_thread,
      sender_name: @current_user.name,
      profile_image: @sender_profile_image
    })

    render json: { message: 'direct thread updated successfully.'}, status: :ok
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

  def put_s3(data, extension, mime_type, folder)
    unique_time = Time.now.strftime("%Y%m%d%H%M%S")
    file_name = Digest::SHA1.hexdigest(data)  + unique_time + extension
    s3 = Aws::S3::Resource.new
    bucket = s3.bucket("rails-blog-minio")
    obj = bucket.object("#{folder}/#{file_name}")

    obj.put(
      acl: "public-read",
      body: data,
      content_type: mime_type,
      content_disposition: "inline"
    )

    obj.public_url
  end

  def delete_from_s3(url)
    s3 = Aws::S3::Resource.new
    bucket_name = "rails-blog-minio"
    file_path = url.split("#{bucket_name}/").last
    bucket = s3.bucket(bucket_name)
    obj = bucket.object(file_path)
  
    obj.delete
  end
end
