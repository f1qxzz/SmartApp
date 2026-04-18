const asyncHandler = require('../../middleware/asyncHandler');
const aiService = require('./ai.service');

const chatWithAI = asyncHandler(async (req, res) => {
  const { message } = req.body;

  if (!message || !String(message).trim()) {
    return res.status(400).json({ success: false, message: 'message is required' });
  }

  const answer = await aiService.askAI({
    userId: req.user._id,
    message: String(message).trim(),
  });

  return res.status(200).json({
    success: true,
    data: {
      answer,
    },
  });
});

const handleSummarizeChat = asyncHandler(async (req, res) => {
  const { chatId } = req.body;

  if (!chatId) {
    return res.status(400).json({ success: false, message: 'chatId is required' });
  }

  const summary = await aiService.summarizeChat({
    chatId,
    userId: req.user._id,
  });

  return res.status(200).json({
    success: true,
    data: {
      summary,
    },
  });
});

module.exports = {
  chatWithAI,
  handleSummarizeChat,
};

