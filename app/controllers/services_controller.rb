class ServicesController < ApplicationController
  respond_to :json

  def getAllCanvasesLayersLists
    responseHash = Hash.new
    layersArray = Array.new

    layers = AnnotationLayer.all
    layers.each do | layer |
      layerHash = Hash.new
      layerHash[:layer_id] = layer['layer_id']
      layerHash[:label] = layer.label
      layerHash[:motivation] = layer.motivation

      listsMap = LayerListsMap.where(layer_id: layer['layer_id'])
      listArray = Array.new
      listsMap.each do |listMap|
        listHash = Hash.new
        listHash[:sequence] = listMap.sequence
          p " listMap.list_id: " + listMap.list_id.to_s
          annoList = AnnotationList.where(list_id: listMap.list_id).first
          annotationResources = JSON.parse(annoList.resources)
          annotationHash = Hash.new
          annotations = annotationResources['resources']
          annotationArray = Array.new

          annotations.each do |resource|
            annotationHash = Hash.new
            annotationHash[:id] = resource['layer_id']
            annotationHash[:type] = resource['type']
            annotationHash[:resourceContent] = resource['resource']['chars']
            p  annotationHash[:resourceContent]
            annotationArray.push(annotationHash)
          end
        listHash.store(:annotations, annotationArray)
        listArray.push(listHash)
      end

      layerHash.store(:lists, listArray)
      layersArray.push(layerHash)
    end

    responseHash[:layers] = layersArray
    respond_to do | format |
      format.json { render json: responseHash }
    end
  end

  def getLayersListsForCanvas
    canvasId = params["canvasId"].to_s
    p 'canvasId = ' +  canvasId
    responseHash = Hash.new
    layersArray = Array.new

    layers = AnnotationLayer.where("layer_id LIKE ?", "%#{canvasId}%")
    layers.each do | layer |
      layerHash = Hash.new
      layerHash[:layer_id] = layer['layer_id']
      layerHash[:label] = layer.label
      layerHash[:motivation] = layer.motivation

      listsMap = LayerListsMap.where(layer_id: layer['layer_id'])
      listArray = Array.new
      listsMap.each do |listMap|
        listHash = Hash.new
        listHash[:sequence] = listMap.sequence
        annoList = AnnotationList.where(list_id: listMap.list_id).first
        annotationResources = JSON.parse(annoList.resources)
        annotationHash = Hash.new
        annotations = annotationResources['resources']
        annotationArray = Array.new

        annotations.each do |resource|
          annotationHash = Hash.new
          annotationHash[:id] = resource['layer_id']
          annotationHash[:type] = resource['type']
          annotationHash[:resourceContent] = resource['resource']['chars']
          annotationArray.push(annotationHash)
        end
        listHash.store(:annotations, annotationArray)
        listArray.push(listHash)
      end

      layerHash.store(:lists, listArray)
      layersArray.push(layerHash)
    end

    responseHash[:layers] = layersArray
    respond_to do | format |
      format.json { render json: responseHash }
    end
  end
end