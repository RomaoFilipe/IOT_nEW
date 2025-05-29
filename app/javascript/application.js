// Libs externas
import "@hotwired/turbo-rails";
import "@hotwired/stimulus";
import Rails from "@rails/ujs";
import "flatpickr";
import "flatpickr/dist/themes/material_green.css";
import "bootstrap";
import "@popperjs/core";
import "jquery";
import "channels"
import { createIcons, icons } from "lucide";


// Rails & Turbo setup
Rails.start();
window.Stimulus = Stimulus.Application.start();

// Stimulus controllers
import "controllers";
import IrrigationStatusController from "./controllers/irrigation_status_controller";
Stimulus.register("irrigation-status", IrrigationStatusController);

// WebSocket canais
import "channels"; // importa consumer + index.js (evita duplicar)
import "./init/irrigation_setup"; // ✅ AQUI está bem

// Lógica de funcionalidades extra
import "./three_scene";
import "./field_management";

// DOMContentLoaded
document.addEventListener("DOMContentLoaded", function () {
  // Logout
  const logoutLink = document.getElementById("logout-link");
  const signOutPath = document.body.getAttribute("data-sign-out-path");
  const signInPath = document.body.getAttribute("data-sign-in-path");

  if (logoutLink) {
    logoutLink.addEventListener("click", function (event) {
      event.preventDefault();
      fetch(signOutPath, {
        method: "DELETE",
        headers: {
          "X-CSRF-Token": document
            .querySelector("meta[name='csrf-token']")
            .getAttribute("content"),
        },
      }).then(() => {
        window.location.href = signInPath;
      });
    });
  }

  // Flash messages e login popup
  const flashNotice = document.getElementById("flash-notice");
  const loginPopup = document.getElementById("login-popup");

  if (flashNotice) {
    flashNotice.classList.add("show");
    setTimeout(() => flashNotice.classList.remove("show"), 5000);
    setTimeout(() => flashNotice.remove(), 5500);
  }

  if (loginPopup) {
    loginPopup.classList.add("show");
    setTimeout(() => loginPopup.classList.add("hide"), 5000);
    setTimeout(() => loginPopup.remove(), 5500);
  }

  // Campo horário do checkbox 'All Day'
  const allDayCheckbox = document.getElementById("all_day_checkbox");
  const timeFields = document.getElementById("time_fields");

  function toggleTimeFields() {
    if (!allDayCheckbox || !timeFields) return;
    timeFields.style.display = allDayCheckbox.checked ? "none" : "block";
  }

  if (allDayCheckbox) {
    allDayCheckbox.addEventListener("change", toggleTimeFields);
    toggleTimeFields();
  }

  // FullCalendar
  const calendarEl = document.getElementById("calendar");
  if (calendarEl) {
    const calendar = new Calendar(calendarEl, {
      plugins: [dayGridPlugin, timeGridPlugin, interactionPlugin],
      initialView: "dayGridMonth",
      locale: "pt-br",
      editable: true,
      selectable: true,
      events: "/crop_events.json",
      dateClick: function (info) {
        window.location.href = `/crop_events/new?start_time=${info.dateStr}`;
      },
    });

    calendar.render();
  }

  // Lucide icons
  createIcons({ icons });
});

// Turbo-specific load
document.addEventListener("turbo:load", () => {
  flatpickr("input[id^='timepicker-']", {
    enableTime: true,
    noCalendar: true,
    dateFormat: "H:i",
    time_24hr: true,
    minuteIncrement: 5,
  });
});
