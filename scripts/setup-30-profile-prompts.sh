# Interactive profile values for later steps (sourced by ../setup.sh).

print_step "Collecting profile values (name/email/domain)"
read -r -p "Full name [Your Name]: " NAME_INPUT
NAME="${NAME_INPUT:-Your Name}"
read -r -p "Email [you@your-domain.com]: " EMAIL_INPUT
EMAIL="${EMAIL_INPUT:-you@your-domain.com}"
read -r -p "Website/Domain [your-domain.com]: " DOMAIN_INPUT
DOMAIN="${DOMAIN_INPUT:-your-domain.com}"
read -r -p "Computer name (menu bar / sharing) [${NAME}]: " COMPUTER_NAME_INPUT
COMPUTER_NAME="${COMPUTER_NAME_INPUT:-$NAME}"
