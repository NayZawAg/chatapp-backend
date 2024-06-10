class TDirectMessage < ApplicationRecord
  belongs_to :send_user, class_name: "MUser", foreign_key: "send_user_id"
end
