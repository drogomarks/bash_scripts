#!/bin/bash

echo -e  "Hi. I am Skynet. What is your name?"
read NAME

if [ "$NAME" == "justin" ] || [ "$NAME" == "Justin" ];then
    echo -e "\nSup dawg! I heard your mad tracks, I'm your biggest fan!"
    sleep 1

else
    echo -e "Oh...I was expecting someone else. \n"
    sleep 1
    echo -e "It's okay though, its great to meet you $NAME."


fi


echo -e "Alright $NAME, let's talk about for loops. \n"

sleep 1

echo -e "For loops let us go over a list of things and do stuff to it, let me show you."

sleep 1

echo -e "Tell me a word, any word:"
read WORD1

echo -e "Okay, another word:"
read WORD2

echo -e "and...one more word:"
read WORD3


echo -e "Alrigt our list is: $WORD1, $WORD2 and $WORD3. \n"

sleep 1


echo -e "Now let's do something as we 'loop' through our list with a for loop."
echo -e "I am will mark each iteration with 'Now we're looping through --->' \n"


for i in $WORD1 $WORD2 $WORD3;
   do
      echo -e "Now we're looping through ---> $i \n"
      sleep 1
   done

echo -e "See $NAME, scripting is awesome and not too hard. Look at this sript in an editor and use it to make your own. Can you figure out what is hapening in the script by looking at it and comparing that to what happens?"
