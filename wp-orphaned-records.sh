
#!/opt/homebrew/bin/bash

site="powerautoraxx"
env="live"
is_multisite="y"
url="webops.live"

report_location="/Users/$(whoami)/Reports/WP/${site}-orphaned-records.md"

# Create a manual array of numbers (1,2,3) to loop through.
blog_id_list="1 2 9 10 28 35 36 37 42 47"



echo "Running orphaned and cached records check on ${site}.${env}..." >> $report_location
# Loop through the blog IDs
for blog_id in $blog_id_list
do
    post_table="wp_${blog_id}_posts"
    postmeta_table="wp_${blog_id}_postmeta"
    term_table="wp_${blog_id}_terms"
    termmeta_table="wp_${blog_id}_termmeta"
    user_table="wp_users"
    usermeta_table="wp_usermeta"

    # If the blog ID is one, adjust the table names.
    if [ $blog_id -eq 1 ]
    then
        post_table="wp_posts"
        postmeta_table="wp_postmeta"
        term_table="wp_terms"
        termmeta_table="wp_termmeta"
    fi

    # Post Meta query
    pm_sql_statement="SELECT COUNT(meta_id) FROM ${postmeta_table} WHERE post_id NOT IN (SELECT ID FROM ${post_table});"

    # Term Meta Query
    tm_sql_statement="SELECT COUNT(meta_id) FROM ${termmeta_table} WHERE term_id NOT IN (SELECT term_id FROM ${term_table});"

    # User Meta Query
    um_sql_statement="SELECT COUNT(umeta_id) FROM ${usermeta_table} WHERE user_id NOT IN (SELECT ID FROM ${user_table});"

    # Stale oEmbed
    oe_sql_statement="SELECT COUNT(meta_id) FROM ${postmeta_table} WHERE meta_key LIKE '%_oembed_%';"


    # Calculate the percentage of revisions
    # Make a variable in YYYY-MM-DD for January 1st of the current year
    current_year=$(date +%Y)
    january_first="${current_year}-01-01"


    rev_percentage_sql_statement="SELECT COUNT(ID) as 'Total Revisions', (SELECT COUNT(ID) FROM ${post_table} WHERE post_type != 'revision') as 'Total Posts', (SELECT COUNT(ID) FROM ${post_table}) as 'Total Posts and Revisions', (SELECT COUNT(ID) FROM ${post_table} WHERE post_type = 'revision'  AND post_date < '${january_first}') as 'Total Revisions', (SELECT COUNT(ID) FROM ${post_table} WHERE post_type = 'revision' AND post_date < '${january_first}') / (SELECT COUNT(ID) FROM ${post_table}) * 100 as 'Percentage of Revisions' FROM ${post_table} WHERE post_type = 'revision' AND post_date < '${january_first}';"
    
    # Run each of the queries above via terminus, and write to markdown file
    echo "## Blog ID: ${blog_id}" >> $report_location
    echo "### Post Meta" >> $report_location
    terminus wp ${site}.${env} -- db query "${pm_sql_statement}" | tail -n +2 >> $report_location
    echo "### Term Meta" >> $report_location
    terminus wp ${site}.${env} -- db query "${tm_sql_statement}" | tail -n +2 >> $report_location
    echo "### User Meta" >> $report_location
    terminus wp ${site}.${env} -- db query "${um_sql_statement}" | tail -n +2 >> $report_location
    echo "### Stale oEmbed" >> $report_location
    terminus wp ${site}.${env} -- db query "${oe_sql_statement}" | tail -n +2 >> $report_location
    echo "### Percentage of Revisions" >> $report_location
    terminus wp ${site}.${env} -- db query "${rev_percentage_sql_statement}" | tail -n +2 >> $report_location  
    echo "---" >> $report_location
done




