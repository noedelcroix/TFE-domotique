import React from 'react';
import {
  Text,
  StyleSheet
} from 'react-native';

import {} from 'react-native/Libraries/NewAppScreen';

const App = () => {
  return (
    <>
    <Text style={ style.text1 }>Azertyuiop</Text>
    <Text style={ style.text2 }>qsdfghjklm</Text>
    <Text style={ style.text3 }>wxcvbn</Text>
    </>
  );
};

const style = StyleSheet.create({
  text1: {
    color: "blue"
  },
  text2: {
    color: "red"
  },
  text3: {
    color: "yellow"
  }
});

export default App;
