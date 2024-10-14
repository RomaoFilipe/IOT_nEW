import "@hotwired/turbo-rails";
import "controllers";
import Rails from "@rails/ujs";
Rails.start();

document.addEventListener("DOMContentLoaded", function() {
    const logoutLink = document.getElementById("logout-link");
  
    if (logoutLink) {
      logoutLink.addEventListener("click", function(event) {
        event.preventDefault();
        fetch('<%= destroy_user_session_path %>', {
          method: 'DELETE',
          headers: {
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
          }
        }).then(() => {
          window.location.href = "<%= new_user_session_path %>";
        });
      });
    }
  });