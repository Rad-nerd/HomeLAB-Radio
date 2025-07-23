document.addEventListener('DOMContentLoaded', (event) => {
    const displayElement = document.querySelector('.webrx-actual-freq');

    if (!displayElement) {
        console.error("Error: Element with class 'webrx-actual-freq' not found.");
        return;
    }

    const separator = " "; // Changed from " | " to " "
    const marqueeWord = "---------HomeLAB-Radio";
    let currentMarqueeDisplay = marqueeWord;

    function updateTitleMarquee() {
        let staticPart = displayElement.textContent || displayElement.innerText;

        // Take only the first 8 characters of the static part
        staticPart = staticPart.substring(0, 8).trim();

        // Ensure there's always something in the static part
        if (staticPart === "") {
            staticPart = "NO_FREQ";
        }

        // Take the first character of the marquee and move it to the end
        currentMarqueeDisplay = currentMarqueeDisplay.substring(1) + currentMarqueeDisplay.substring(0, 1);

        // Update the full browser title
        document.title = staticPart + separator + currentMarqueeDisplay;

        // Schedule the function to run again
        setTimeout(updateTitleMarquee, 150); // Adjust speed here (milliseconds)
    }

    // Start the marquee after a short initial delay
    setTimeout(updateTitleMarquee, 500);
});

document.addEventListener('DOMContentLoaded', () => {
    const typeffectElement = document.getElementById('typeffect');

    // Now you can add as many phrases as you like here!
    const phrases = [
        "HomeLAB-RADIO",
        "Made By Rad-nerd",
        "HomeLAB-RADIO", // New phrase
        "Powered by OpenWebRX+"
    ];

    let phraseIndex = 0;
    let charIndex = 0;
    const typingSpeed = 80;
    const erasingSpeed = 40;

    const pauseAfterTyping = 5000;
    const pauseAfterErasing = 1000;

    function type() {
        if (charIndex < phrases[phraseIndex].length) {
            typeffectElement.textContent += phrases[phraseIndex].charAt(charIndex);
            charIndex++;
            setTimeout(type, typingSpeed);
        } else {
            setTimeout(erase, pauseAfterTyping);
        }
    }

    function erase() {
        if (charIndex > 0) {
            typeffectElement.textContent = phrases[phraseIndex].substring(0, charIndex - 1);
            charIndex--;
            setTimeout(erase, erasingSpeed);
        } else {
            // Cycle through ALL phrases
            phraseIndex++;
            if (phraseIndex >= phrases.length) {
                phraseIndex = 0; // Loop back to the first phrase
            }

            setTimeout(type, pauseAfterErasing);
        }
    }

    type();
});
