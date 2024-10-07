document.getElementById('login-form').addEventListener('submit', function(event) {
    event.preventDefault(); // Impede o envio do formulário

    // Aqui você pode adicionar a lógica para autenticar o usuário
    const username = this.username.value;
    const password = this.password.value;

    console.log(`Username: ${username}, Password: ${password}`);
    alert('Login realizado com sucesso!'); // Exemplo de feedback
});
