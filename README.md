# 3rd
only for test purpose

## clone parent and child
git clone https://github.com/Martians/3rd.git --recursive

or

git submodule update --init --recursive

cd 3rd

## switch child branch
git submoduel foreach 'git co master ||:'
