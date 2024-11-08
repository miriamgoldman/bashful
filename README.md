# bashful

**Bashful** is a collection of Bash utilities aimed at simplifying tasks related to media handling, backups, and configurations for WordPress, Pantheon, and Acquia environments. Ideal for developers and administrators, this repository provides tools to streamline operations and enhance productivity.

## Features

- **Ease of Use**: Simple, single-command scripts for efficient workflows.
- **Modular Design**: Scripts are organized by environment and function.
- **Customizable**: Easily adaptable to various server and site configurations.

## Installation

1. **Clone the Repository:**

   `git clone https://github.com/miriamgoldman/bashful.git`

2. **Make the Scripts Executable:**

   `chmod +x *.sh`

3. **(Optional) Add to PATH**:

   To access the scripts globally, add the `bashful` directory to your PATH:

   `export PATH=$PATH:/path/to/bashful`

## Usage

### Root-Level Scripts

1. **image-variants.sh**  
   Analyzes all images, identifies size variants, and calculates potential storage savings if these variants are removed.

2. **db-backup-analysis.sh**  
   Analyzes and provides information about database backups.

### WordPress Directory

1. **wp-media-regen-multisite.sh**  
   Regenerates media for a WordPress multisite.

### Pantheon Directory

1. **multisite-add-domains.sh**  
   Adds domains to a Pantheon multisite configuration.

2. **pantheon-rclone-config.sh**  
   Configures `rclone` for syncing Pantheon files.

### Acquia-to-Pantheon Directory

1. **acquia-migrate-files-db.sh**  
   Migrates files and databases from Acquia to Pantheon.

2. **acquia-multisite-filesize.sh**  
   Calculates and displays file sizes for an Acquia multisite.

3. **acquia-multisite-db-size.sh**  
   Shows the database size for each Acquia multisite.


## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
