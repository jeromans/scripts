
#!/bin/bash

# Function to exit in case of error
exit_on_error() {
    echo "Error: $1"
    exit 1
}

# GitHub Personal Access Token - should be set as an environment variable for security
GITHUB_TOKEN=$GITHUB_PAT
[ -z "$GITHUB_TOKEN" ] && exit_on_error "GitHub token not found"

# Repository name is the name of the current directory
REPO_NAME=$(basename "$PWD")

# GitHub username - replace with your GitHub username
GITHUB_USER="jeromans"

# Check if .git exists, if not initialize a new git repository
if [ ! -d ".git" ]; then
    git init || exit_on_error "Failed to initialize git"
fi

# Add all files and commit
git add .

#git commit -m "Initial commit"
#[ $? -ne 0 ] && exit_on_error "Git commit failed"

# Check if there are changes to commit
if git diff --staged --quiet; then
    echo "No changes to commit. Working tree is clean."
else
    # Commit changes
    git commit -m "Initial commit" || exit_on_error "Git commit failed"
fi


# Check if the GitHub repo already exists
repo_check_url="https://api.github.com/repos/$GITHUB_USER/$REPO_NAME"
repo_exists=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: token $GITHUB_TOKEN" $repo_check_url)

echo "Check for $repo_check_url  returned $repo_exists "

if [ $repo_exists -eq 200 ]; then
    echo "Repository already exists on GitHub. Skipping creation."
    REPO_URL=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$repo_check_url" | jq -r '.clone_url')
    echo "REPO_URL is $REPO_URL"
    if [ -z "$REPO_URL" ]; then
        exit_on_error "Failed to extract repository URL 1."
    fi
else
   # Create a new repo on GitHub
   # Requires jq for parsing JSON - ensure jq is installed
   CREATE_REPO_JSON=$(curl -s -H "Authorization: token $GITHUB_TOKEN" -d "{\"name\":\"$REPO_NAME\"}" https://api.github.com/user/repos)
   [ $? -ne 0 ] && exit_on_error "Failed to create repository on GitHub"
   # Extract repo URL from response (using jq)
   REPO_URL=$(echo $CREATE_REPO_JSON | jq -r '.clone_url')
   [ -z "$REPO_URL" ] && exit_on_error "Failed to extract repository URL 2."
fi

echo "So far so good"

# https://github.com/jeromans/MakeFun
# https://github.com/jeromans/MakeFun.git'


# Encode the token for URL usage
#ENCODED_GITHUB_TOKEN=$(python -c "import urllib.parse; print(urllib.parse.quote_plus('$GITHUB_TOKEN'))")

# Construct the remote repository URL with the token
#REMOTE_URL_WITH_TOKEN="https://$ENCODED_GITHUB_TOKEN@github.com/$GITHUB_USER/$REPO_NAME.git"

REMOTE_URL="https://github.com/$GITHUB_USER/$REPO_NAME.git"

# Check if the remote 'origin' already exists
if git remote | grep -q 'origin'; then
    echo "Remote 'origin' already exists. Updating URL."
    git remote set-url origin "${REMOTE_URL}" || exit_on_error "Failed to update remote repository URL ${REMOTE_URL}"
else
    echo "Adding remote 'origin'."
    git remote add origin "${REMOTE_URL}" || exit_on_error "Failed to add remote repository URL ${REMOTE_URL}"
fi


# Set remote 
# git remote add origin "${REPO_URL}" || exit_on_error "Failed to add remote repository"

# push
git push -u origin main || exit_on_error "Failed to push to remote repository"

echo "Repository successfully created and pushed to GitHub"



