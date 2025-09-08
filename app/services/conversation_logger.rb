# app/services/conversation_logger.rb
class ConversationLogger
  def self.log!(uid:, model:, messages:, reply:, usage: nil)
    # TODO: ActiveRecordモデルに保存（例：conversations, messages テーブル）
    Rails.logger.info(
      message: "chat_log",
      uid: uid,
      model: model,
      prompt_tokens: usage&.dig("prompt_tokens"),
      completion_tokens: usage&.dig("completion_tokens"),
      total_tokens: usage&.dig("total_tokens"),
      messages: messages,
      reply: reply
    )
  end
end
