class TDirectThread < ApplicationRecord
  belongs_to :t_direct_message
  has_many :passive_relationships, class_name:  "TDirectThreadMsgFile",
                                    foreign_key: "diirectmsgid",
                                    dependent:   :destroy
end
