
import { Calendar } from '@fullcalendar/core';
import dayGridPlugin from '@fullcalendar/daygrid';
import timeGridPlugin from '@fullcalendar/timegrid';
import interactionPlugin from '@fullcalendar/interaction'; // Import necessário para a seleção de datas
import "@hotwired/turbo-rails";
import "controllers";
import Rails from "@rails/ujs";
Rails.start();

document.addEventListener("DOMContentLoaded", function() {
    // Lógica para logout
    const logoutLink = document.getElementById("logout-link");
    const signOutPath = document.body.getAttribute('data-sign-out-path');
    const signInPath = document.body.getAttribute('data-sign-in-path');

    if (logoutLink) {
        logoutLink.addEventListener("click", function(event) {
            event.preventDefault();
            fetch(signOutPath, {
                method: 'DELETE',
                headers: {
                    'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
                }
            }).then(() => {
                window.location.href = signInPath;
            });
        });
    }

    // Flash messages e Popup lógica
    const flashNotice = document.getElementById("flash-notice");
    const loginPopup = document.getElementById("login-popup");

    if (flashNotice) {
        // Mostra o flash com animação
        flashNotice.classList.add("show");

        // Aguarda 5 segundos para o flash desaparecer
        setTimeout(function() {
            flashNotice.classList.remove("show");
            flashNotice.classList.add("hide");
        }, 5000);

        // Remove o flash da DOM após 5.5 segundos
        setTimeout(function() {
            flashNotice.remove();
        }, 5500);
    }

    if (loginPopup) {
        // Exibe o popup
        loginPopup.classList.add("show");

        // Aguarda 5 segundos para o popup desaparecer
        setTimeout(function() {
            loginPopup.classList.add("hide");
        }, 5000);

        // Remove o popup da DOM após 5.5 segundos
        setTimeout(function() {
            loginPopup.remove();
        }, 5500);
    }

    // Manipulação da exibição do campo de horas com checkbox 'All Day'
    const allDayCheckbox = document.getElementById('all_day_checkbox');
    const timeFields = document.getElementById('time_fields');

    function toggleTimeFields() {
        if (allDayCheckbox && timeFields) {
            if (allDayCheckbox.checked) {
                timeFields.style.display = 'none';
            } else {
                timeFields.style.display = 'block';
            }
        }
    }

    if (allDayCheckbox) {
        allDayCheckbox.addEventListener('change', toggleTimeFields);
        toggleTimeFields(); // Executa a função ao carregar a página
    }

    // FullCalendar Initialization
    const calendarEl = document.getElementById('calendar');
    if (calendarEl) {
        var calendar = new Calendar(calendarEl, {
            plugins: [dayGridPlugin, timeGridPlugin, interactionPlugin], // Adiciona plugins necessários
            initialView: 'dayGridMonth', // Exibe a visualização de mês no início
            locale: 'pt-br', // Coloca a linguagem do calendário em português
            editable: true, // Permite a edição de eventos
            selectable: true, // Permite seleção de datas
            events: '/crop_events.json', // Carrega os eventos via JSON
            dateClick: function(info) {
                // Redireciona para a criação de eventos ao clicar em uma data
                window.location.href = `/crop_events/new?start_time=${info.dateStr}`;
            }
        });

        calendar.render();
    }
});
