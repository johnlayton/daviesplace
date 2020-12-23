## sumo

### Setup oh-my-zsh

#### Pre-requisite - Install json-query 
```zsh
pushd $ZSH/custom/plugins && \
  git clone git@github.com:johnlayton/torbaystreet.git json-query && \
  popd || echo "I'm broken"
```
```zsh
plugins=(... json-query)
```

#### Install sumo plugin
```zsh
pushd $ZSH/custom/plugins && \
  git clone git@github.com:johnlayton/daviesplace.git sumo && \
  popd || echo "I'm broken"
```
```zsh
plugins=(... sumo)
```

### Setup other

```zsh
pushd $HOME && \
  git clone git@github.com:johnlayton/daviesplace.git .sumo && \
  popd || echo "I'm broken"
```

```zsh
source ~/.sumo/sumo.plugin.zsh
```


### Usage

#### 
```zsh
sumo search last-15m "sourcename" | \
 jq -r ".messages" | jqx stream | jq -r ".map._raw" | jqx fields logger_name message
```

#### 
```zsh
```

```zsh
```
