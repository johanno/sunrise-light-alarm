document.addEventListener('DOMContentLoaded', function () {
    const alarmsContainer = document.getElementById('alarmsContainer');
    const addAlarmButton = document.getElementById('addAlarm');
    const alarmPopup = document.getElementById('alarmPopup');
    const saveAlarmButton = document.getElementById('saveAlarm');
    const cancelAlarmButton = document.getElementById('cancelAlarm');

    addAlarmButton.addEventListener('click', function () {
        // Show the popup
        alarmPopup.style.display = 'block';
    });

    cancelAlarmButton.addEventListener('click', function () {
        // Close the popup
        alarmPopup.style.display = 'none';
    });

    saveAlarmButton.addEventListener('click', function () {
        // Make a POST request to Flask endpoint for adding an alarm
        const alarmTime = document.getElementById('alarmTime').value;
        const alarmMusic = document.getElementById('alarmMusic').value;
        const alarmDays = [];

        // Assuming you have checkboxes with IDs alarmMonday, alarmTuesday, etc.
        if (document.getElementById('alarmMonday').checked) alarmDays.push('Mo');
        if (document.getElementById('alarmTuesday').checked) alarmDays.push('Tu');
        if (document.getElementById('alarmWednesday').checked) alarmDays.push('We');
        if (document.getElementById('alarmThursday').checked) alarmDays.push('Th');
        if (document.getElementById('alarmFriday').checked) alarmDays.push('Fr');
        if (document.getElementById('alarmSaturday').checked) alarmDays.push('Sa');
        if (document.getElementById('alarmSunday').checked) alarmDays.push('Su');
        // Add other days

        const newAlarm = {
            time_of_day: alarmTime,
            music: alarmMusic,
            days_of_week: alarmDays,
            enabled: true, // Modify based on your requirements
            // Add other alarm properties as needed
        };
        console.log("newAlarm: ", newAlarm)
        const queryString = Object.entries(newAlarm)
            .map(([key, value]) => `${encodeURIComponent(key)}=${encodeURIComponent(value)}`)
            .join('&');

        const url = `/add_alarm?${queryString}`;

        $.get(url, function (data) {
            console.log("addalarm data: ", data);
            alarmPopup.style.display = 'none';
        })
            .fail(function (error) {
                console.error(error);
            });

    });

    // Fetch existing alarms and update the UI
    fetch('/get_alarms')
        .then(response => response.json())
        .then(data => {
            console.log("data: ", data)
            // Update the alarms list
            updateAlarmsUI(data.alarms);
            // Fetch music files and update the music dropdown
            fetchMusicFiles();
        });

    // Function to fetch music files
    function fetchMusicFiles() {
        $.get("/list_music_files", function (files) {
            const musicDropdown = document.getElementById("alarmMusic");

            // Inside the fetchMusicFiles function after retrieving the list
            const musicSelect = document.getElementById("alarmMusic");

            // Clear existing options
            musicSelect.innerHTML = "";

            // Populate the select element with fetched music files
            files.music_files.forEach((file) => {
                const option = document.createElement("option");
                option.value = file;
                option.text = file;
                musicSelect.appendChild(option);
            });
            console.log("files: ", files)
            console.log("music_files: ", files.music_files)
            // You can call any functions or perform additional actions after fetching music files
            // For example, you can now call the function to update the alarms UI
            updateAlarmsUI(files.alarms);
        });
    }

    function updateAlarmsUI(alarms) {
        // Clear existing alarms
        alarmsContainer.innerHTML = '';

        // Update UI with the new alarms
        alarms.forEach(alarm => {
            const alarmDiv = document.createElement('div');
            alarmDiv.innerHTML = `
                <input type="checkbox" id="${alarm.id}" ${alarm.enabled ? 'checked' : ''}>
                <label for="${alarm.id}">${alarm.time_of_day} - ${alarm.music} - ${alarm.days_of_week.join(', ')}</label>
            `;
            alarmsContainer.appendChild(alarmDiv);
        });
    }
});
