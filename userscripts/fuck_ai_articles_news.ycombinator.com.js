// ==UserScript==
// @name        Remove AI shit from HN
// @namespace   Violentmonkey Scripts
// @match       https://news.ycombinator.com/*
// @grant       none
// @version     1.0
// @author      @k@layer8.space + rage
// @description 10/4/2024, 3:29:19 AM
// ==/UserScript==

(function() {
    'use strict';

    const keywords = ["llm", "rnn", "agi", "chatgpt", "-70b", "-100b", "flux", "ai", "llama", "openai"];

    const containskeywords = (text) => keywords.some(keyword => text.toLowerCase().includes(keyword));
    const removeelement = (elem) => elem && (elem.style.display = 'none');
    const rows = document.querySelectorAll('tr.athing');

    rows.forEach(row => {
        const titleelement = row.querySelector('.title a');
        if (titleelement && containskeywords(titleelement.textContent)) {
            removeelement(row);
            removeelement(row.nextElementSibling);
            removeelement(row.previousElementSibling);
        }
    });
})();
