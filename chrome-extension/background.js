async function sendToggle(tabId) {
  try {
    await chrome.tabs.sendMessage(tabId, { type: "META_VIEWER_TOGGLE" });
  } catch (_) {
    await chrome.scripting.insertCSS({
      target: { tabId },
      files: ["panel.css"]
    });
    await chrome.scripting.executeScript({
      target: { tabId },
      files: ["content.js"]
    });
    await chrome.tabs.sendMessage(tabId, { type: "META_VIEWER_TOGGLE" });
  }
}

chrome.action.onClicked.addListener((tab) => {
  if (!tab.id) return;

  sendToggle(tab.id).catch(() => {
    // Browser-internal and restricted pages cannot receive injected scripts.
  });
});
