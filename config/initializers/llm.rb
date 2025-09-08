# config/initializers/llm.rb
# ------------------------------------------------------------
# LLM 全体設定（今はログレベル/タイムアウト程度）
# ------------------------------------------------------------
Rails.application.configure do
  config.x.llm = ActiveSupport::OrderedOptions.new
  config.x.llm.timeout = ENV.fetch('LLM_TIMEOUT', '20').to_i
end
